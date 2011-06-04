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

require "ruby_parser"
require "partialruby"
require "sexp_processor"

module SandboxedErb
  class TreeProcessor < SexpProcessor
    
    def initialize
      super()
      self.default_method = :fallback_process
      self.require_empty = false
      self.warn_on_default = false
      
      @hook_handler_name = "@_hook_handler".intern
      @last_line_number = 0
    end
    
    #we treat this same as a call
    def process_attrasgn(tree)
      process_call(tree)
    end
    
    def process_call(tree)
      puts tree.inspect if $DEBUG
      if [:_sbm].include?(tree[2]) 
        raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: #{tree[2].to_s} is a reserved method"
      elsif tree[1] 
        #rewrite obj.call(arg1, arg2, argN) to obj._invoke_sbm(:call, arg1, arg2, argN)
        args = [:arglist]
        args << s(:lit, tree[2])
        for i in 1...tree[3].length
          args << tree[3][i]
        end
        add_line_number(tree, s(:call, process(tree[1]), :_sbm, process(args)))
      else
        #call on mixed in method or passed in variable 
        receiver = s(:self)
        #rewrite local_call(arg1, arg2, argN) to self._get_local(:local_call, arg1, arg2, argN)
        args = [:arglist]
        args << s(:lit, tree[2])
        for i in 1...tree[3].length
          args << tree[3][i]
        end
        add_line_number(tree, s(:call, s(:self), :_get_local, process(args)))
      end
    end
    
    #disallowed
    
    def process_iasgn(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot assign instance members in a template"
    end
    
    def process_ivar(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot access instance members in a template"
    end
    
    def process_cvasgn(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot assign class members in a template"
    end
    
    def process_cvdecl(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot declare class members in a template"
    end
    
    def process_cdecl(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot define a constant in a template"
    end
    
    def process_const(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot access a constant in a template"
    end
     
    def process_class(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot define a class in a template"
    end
    
    def process_module(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot define a module in a template"
    end
    
    def process_defn(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot define a method in a template"
    end
    
    def process_defs(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot define a method in a template"
    end
    
    def process_super(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot call super in a template"
    end
    
    def process_gvar(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot access global variables in a template"
    end
    
    def process_gasgn(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot assign global variables in a template"
    end
    
    def process_xstr(tree)
      puts tree.inspect if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot make a system call in a template"
    end
    
    def fallback_process(tree)
      puts tree.inspect if $DEBUG
      puts "Fallback called" if $DEBUG
      raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: Invalid call used: #{tree[0]}"
    end
    
    
    #allowed
    
    [[:block, true],[:lasgn, true],[:arglist, true],[:str, true],[:lit, true],[:lvar, true],[:for, true], [:while, true], [:do, true], [:if, true], [:case, true], [:when, true], [:array, true], [:hash, true]].each { |action, add_line_number|
      if add_line_number
        define_method "process_#{action}".intern do |tree|
          puts tree.inspect if $DEBUG
          add_line_number(tree, passthrough(tree))
        end
      else
        define_method "process_#{action}".intern do |tree|
          puts tree.inspect if $DEBUG
          passthrough tree
        end
      end
    }
    
    
    
  private
  #taken from SexpProcessor: just process the tag by processing all nested tags, leaving current tag untouched...
    def passthrough(exp)
      result = self.expected.new
      type = exp.first
      exp_orig = nil

      in_context type do
        until exp.empty? do
          sub_exp = exp.shift
          sub_result = nil
          if Array === sub_exp then
            sub_result = error_handler(type, exp_orig) do
              process(sub_exp)
            end
            raise "Result is a bad type" unless Array === sub_exp
            raise "Result does not have a type in front: #{sub_exp.inspect}" unless Symbol === sub_exp.first unless sub_exp.empty?
          else
            sub_result = sub_exp
          end
          result << sub_result
        end
  
        begin
          result.sexp_type = exp.sexp_type
        rescue Exception
          # nothing to do, on purpose
        end
      end
      result
    end
    
    def add_line_number(original_tree, processed_tree)
      if original_tree.respond_to?(:line) &&  @last_line_number != original_tree.line && !original_tree.line.nil?
        puts "@last_line_number (#{@last_line_number}) != original_tree.line (#{original_tree.line})" if $DEBUG
        @last_line_number = original_tree.line
        s(:block, s(:call, nil, :_sln, s(:arglist, s(:lit, original_tree.line))), processed_tree)
      else
        processed_tree
      end
    end
    
  end
end

