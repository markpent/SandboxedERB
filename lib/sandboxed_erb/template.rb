=begin

This file is part of the sandboxed_erb project, https://github.com/markpent/SandboxedERB

Copyright (c) 2011 Mark Pentland <mark.pent@gmail.com>

sandboxed_erb is free software: you can redistribute it and/or modify
it under the terms of the gnu general public license as published by
the free software foundation, either version 3 of the license, or
(at your option) any later version.

sandboxed_erb is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.  see the
gnu general public license for more details.

you should have received a copy of the gnu general public license
along with shikashi.  if not, see <http://www.gnu.org/licenses/>.

=end

require "erb"
require "partialruby"

module SandboxedErb
  
#This class represents a template which can be compiled then run multiple times.
#
#When declaring a template, pass an array of Mixin classes to the contructor to allow the template access to the Mixin methods.
#
#Example
# module ExampleHelper
#   def format_date(date, format)
#     if format == :short_date
#       date.strftime("%d %b %Y %H:%M")
#     else
#       "unknown format: #{format}"
#     end
#   end
#
#    def current_time
#      DateTime.now
#    end
# end
#
# template = SandboxedErb::Template.new([ExampleHelper])
# #the template will now have access to the format_date() and current_time() helper function
# template.compile('the date = <%=format_date(current_time, :short_date)%>')

  class Template
    
    #minins is an array of helper classes which expose methods to the template 
    def initialize(mixins = [])
      @mixins = mixins.collect { |clz| "include #{clz.name}"}.join("\n")
    end
    
    #compile the template
    #
    #if the template does not compile, false is returned and get_error should be called to get the compile error.
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
    
    #run a compiled template
    #* context: A map of context objects that will be available to helper functions and instance variables, and available to sandboxed objects through the set_sandbox_context callback.
    #* locals: A map of local objects that will be available to the template, and available to sandboxed objects through the set_sandbox_context callback as the :locals entry.
    #If the template runs successfully, the geneated content is returned. If an error occures, nil is returned and get_error should be called to get the error information.
    def run(context, locals)
      begin
        @template_runner.run(context, locals)
      rescue Exception=>e
        @error = e.message
        nil
      end
    end
    
    def compile_erb_template(str_template) #:nodoc:
      ecompiler = ERB::Compiler.new(nil)
      
      ecompiler.put_cmd = "_erbout.concat"
      ecompiler.insert_cmd = "_erbout.concat"
  
      cmd = []
      cmd.push "_erbout = ''"
      
      ecompiler.pre_cmd = cmd
  
      cmd = []
      cmd.push('_erbout')
  
      ecompiler.post_cmd = cmd
      e_template = ecompiler.compile(str_template)
      if e_template.class == Array #ruby 1.9 returns an array with the encoding prefixed as a comment on the first line...
        e_template = e_template[0].lines.to_a[1..-1].join
      end
      
      e_template
    end
    
    def sandbox_code(erb_template) #:nodoc:
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
  
  class TemplateBase #:nodoc: all
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
      context = {} if context.nil?
      context[:locals] = locals
      unless context.nil?
        for k in context.keys
          eval("@#{k} = context[k]")
        end
      end
      @_sb_context = context
      @_locals = locals
      @_line = 1
      begin
        run_internal
      rescue Exception=>e
        raise "Error on line #{@_line}: #{e.message}"
      ensure
        #cleanup the context
        unless context.nil?
          for k in context.keys
            eval("@#{k} = nil")
          end
        end
         @_sb_context = nil
         @_locals = nil
      end
    end
    
    def _get_local(*args)
      target = args.shift
      #check if the target is in the context
      if @_locals[target]
        @_locals[target]
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