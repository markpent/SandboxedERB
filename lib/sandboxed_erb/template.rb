require "erb"
require "partialruby"

module SandboxedErb
  class Template
    
    def compile(str_template)
      
      erb_template = compile_erb_template(str_template)
      return false if erb_template.nil?
      #we now have a normal compile erb template (which is just ruby code)
      
      sandboxed_compiled_template = sandbox_code(erb_template)
      return false if sandboxed_compiled_template.nil?
      
      @clazz_name = "SandboxedErb::TClass#{self.object_id}"
      @file_name = "tclass_#{self.object_id}"
      
      clazz_str = <<-EOF
      class #{@clazz_name} < SandboxedErb::TemplateBase
        def run_internal()
          #{sandboxed_compiled_template}
        end
      end
      #{@clazz_name}.new
      EOF
      
      begin
        @template_runner = eval(clazz_str, nil, @file_name)
      rescue Exception=>e
        @error = "Invalid code generated: #{e.message}"
        return false
      end
      
      true
      
    end
    
    def run(locals)
      begin
        @template_runner.run(locals)
      rescue Exception=>e
        @error = e.message
        nil
      end
    end
    
    #compile as normal erb template but using out own buffer object (_tbuf)
    def compile_erb_template(str_template)
      ecompiler = ERB::Compiler.new(nil)
      
      ecompiler.put_cmd = "_erbout.concat"
      ecompiler.insert_cmd = "_erbout.concat"
  
      cmd = []
      cmd.push "_erbout = ''"
      
      ecompiler.pre_cmd = cmd
  
      cmd = []
      cmd.push('_erbout')
  
      ecompiler.post_cmd = cmd
      ecompiler.compile(str_template)
    end
    
    def sandbox_code(erb_template)
      begin
        tree = RubyParser.new.parse erb_template
        context = PartialRuby::PureRubyContext.new
        tree_processor = SandboxedErb::TreeProcessor.new()
        
        tree = tree_processor.process(tree)
        emulationcode = context.emul tree
      rescue Exception=>e
        @error = e.message
        return nil
      end
      emulationcode
    end
    
    def get_error
      @error
    end
  end
  
  class TemplateBase
    
    def run(context)
      @context = context
      @line = 1
      begin
        run_internal
      rescue Exception=>e
        raise "Error on line #{@line}: #{e.message}"
      end
    end
    
    def _get_local(*args)
      target = args.shift
      #check if the target is in the context
      if @context[target]
        @context[target]._sbm
      else
        #check if the target is defined in one of the mixin helper functions (TODO)
        nil
      end
    end
    
    def _sln(line_no)
      @line = line_no
    end
  end

end