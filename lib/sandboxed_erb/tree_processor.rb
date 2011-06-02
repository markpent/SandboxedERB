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
    
    def process_call(tree)

      puts tree.inspect if $DEBUG
      if [:_sbm, :_get_local].include?(tree[2]) 
        raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: #{tree[2].to_s} is a reserved method"
      elsif tree[0] == :call && tree[1] && (tree[1][0] == :lvar || tree[1][0] == :lit)
        #this is a method call onto an object... just call sandboxed on the result to make sure we have the safe version
        res = s(:call, s(:call, s(:call, tree[1], :_sbm, s(:arglist)), tree[2], process(tree[3])), :_sbm, s(:arglist))
        add_line_number(tree, res)
      elsif tree[0] == :call && tree[1] && (tree[1][0] == :call)
        #call a method on return value of another call
        res = s(:call, s(:call, process(tree[1]), tree[2], process(tree[3])), :_sbm, s(:arglist))
        add_line_number(tree, res)
      elsif tree[0] == :call && tree[1].nil? 
        #call on mixed in method or passed in variable 
        receiver = s(:self)
        #rewrite local_call(arg1, arg2, argN) to self._get_local(:local_call, arg1, arg2, argN)
        args = [:arglist]
        args << s(:lit, tree[2])
        for i in 1...tree[3].length
          args << tree[3][i]
        end
        add_line_number(tree, s(:call, s(:self), :_get_local, process(args)))
      else
        process(tree[1]) #try and raise more specific error
        raise SandboxedErb::CompileSecurityError, "Line #{tree.line}: You cannot call methods of non-local objects"
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
    
    [[:block, true],[:lasgn, true],[:arglist, true],[:str, true],[:lit, true],[:lvar, true],[:attrasgn, true],[:for, true], [:while, true], [:do, true], [:if, true], [:case, true], [:when, true], [:array, true]].each { |action, add_line_number|
      if add_line_number
        define_method "process_#{action}".intern do |tree|
          add_line_number(tree, passthrough(tree))
        end
      else
        define_method "process_#{action}".intern do |tree|
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

