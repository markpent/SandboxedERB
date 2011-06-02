require "erb"
require "partialruby"

module SandboxedErb
  class Template
    
    def initialize(mixins = [])
      @mixins = mixins.collect { |clz| "include #{clz.name}"}.join("\n")
    end
    
    def compile(str_template)
      
      erb_template = compile_erb_template(str_template)
      return false if erb_template.nil?
      #we now have a normal compile erb template (which is just ruby code)
      
      sandboxed_compiled_template = sandbox_code(erb_template)
      puts sandboxed_compiled_template if $DEBUG
      return false if sandboxed_compiled_template.nil?
      
      @clazz_name = "SandboxedErb::TClass#{self.object_id}"
      @file_name = "tclass_#{self.object_id}"
      
      clazz_str = <<-EOF
      class #{@clazz_name} < SandboxedErb::TemplateBase
        #{@mixins}
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
    
    def run(context, locals)
      begin
        @template_runner.run(context, locals)
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
      @error = nil
      tree = nil
      begin
        tree = RubyParser.new.parse erb_template
      rescue Exception=>e
        #the message is pretty useless.. lets eval the code (it wont get executed because of the compile error)
        begin
          #extra bit of caution.. run in $SAFE=4
          t = Thread.new {
              $SAFE = 4
              eval(erb_template, nil, "line")
          }
          t.join
        rescue Exception=>e2
          @error = e2.message
          return nil
        end
        #if we got here then somehow code that would not compile using RubyParser eval'ed ok...
        throw "SYSTEM ERROR: you may be owned! Code that should not be able to compile has run!"
      end
      begin
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
    def initialize
      @_allowed_methods = {}
      self.class.included_modules.each { |mod|
        unless mod == Kernel
          mod.public_instance_methods.each { |m|
            @_allowed_methods[m.intern] = true
          }
        end
      }
    end
    
    def run(context, locals)
      unless context.nil?
        for k in context.keys
          eval("@#{k} = context[k]")
        end
      end
      @_locals = locals
      @_line = 1
      begin
        run_internal
      rescue Exception=>e
        raise "Error on line #{@_line}: #{e.message}"
      end
    end
    
    def _get_local(*args)
      target = args.shift
      #check if the target is in the context
      if @_locals[target]
        @_locals[target]._sbm
      elsif @_allowed_methods[target] #check if the target is defined in one of the mixin helper functions
        begin
          self.send(target, *args)
        rescue Exception=>e
          raise "Error calling #{target}: #{e.message}"
        end
      else
        raise "Unknown method: #{target}"
      end
    end
    
    def _sln(line_no)
      @_line = line_no
    end
  end

end