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
    end
    
    def process_call(tree)

      puts tree.inspect if $DEBUG
      if tree[0] == :call && tree[1] && (tree[1][0] == :lvar || tree[1][0] == :lit)
        #this is a method call onto an object... just call sandboxed on the result to make sure we have the safe version
        #puts "local call"
        res = s(:call, s(:call, s(:call, tree[1], :sandboxed, s(:arglist)), tree[2], process(tree[3])), :sandboxed, s(:arglist))
        #puts res.inspect
        res
      elsif tree[0] == :call && tree[1] && (tree[1][0] == :call)
        #puts "nested call"
        res = s(:call, s(:call, process(tree[1]), tree[2], process(tree[3])), :sandboxed, s(:arglist))
        #puts res.inspect
        res
      elsif tree[0] == :call && tree[1].nil? 
        if tree[2] == :_get_local #this is reserved!
          s(:call, nil, :raise, s(:arglist, s(:str,"_get_local is a reserved method")))
        else
          #call on mixed in method or passed in variable 
          receiver = s(:self)
          #rewrite local_call(arg1, arg2, argN) to self._get_local(:local_call, arg1, arg2, argN)
          args = [:arglist]
          args << s(:lit, tree[2])
          for i in 1...tree[3].length
            args << tree[3][i]
          end
          s(:call, s(:self), :_get_local, process(args))
        end
        
      else
        s(:call, nil, :raise, s(:arglist, s(:str,"You cannot call methods of non-local objects")))
      end

    end
    
    #disallowed
    
    def process_iasgn(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot assign instance members in a template")))
    end
    
    def process_ivar(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot access instance members in a template")))
    end
    
    def process_cvasgn(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot assign class members in a template")))
    end
    
    def process_cvdecl(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot declare class members in a template")))
    end
    
    def process_cdecl(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot define a constant in a template")))
    end
     
    def process_class(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot define a class in a template")))
    end
    
    def process_module(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot define a module in a template")))
    end
    
    def process_defn(tree)
       puts tree.inspect if $DEBUG
       s(:call, nil, :raise, s(:arglist, s(:str,"You cannot define a method in a template")))
    end
    
    def process_defs(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot define a method in a template")))
    end
    
    def process_super(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot call super in a template")))
    end
    
    def process_gvar(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot access global variables in a template")))
    end
    
    def process_gasgn(tree)
      puts tree.inspect if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"You cannot assign global variables in a template")))
    end
    
    def fallback_process(tree)
      puts tree.inspect if $DEBUG
      puts "Fallback called" if $DEBUG
      s(:call, nil, :raise, s(:arglist, s(:str,"Invalid code used: #{tree.inspect}")))
    end
    
    
    #allowed
    def process_block(tree)
      passthrough tree
    end
    
    def process_lasgn(tree)
      passthrough tree
    end
    
    def process_arglist(tree)
      passthrough tree
    end
    
    def process_str(tree)
      passthrough tree
    end
    
    def process_lit(tree)
      passthrough tree
    end
    
    def process_lvar(tree)
      passthrough tree
    end
    
    
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
  end
end

