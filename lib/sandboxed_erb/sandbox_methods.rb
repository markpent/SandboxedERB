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

#Adds the sandboxed_methods and not_sandboxed_methods to Module class so it is avialble to all classes.
class Module
  
  #Specify what methods you want to be accessable from the sandbox.
  #
  #Example 
  # class SomeClass
  #   sandboxed_methods :some_method
  #   def some_method
  #     "this is ok to call"
  #   end
  # end
  # 
  #If the object has a method called set_sandbox_context, it will be passed the sandbox_context, which is a map containing the context passed to SandboxedErb::Template.run, as well as another entry keys to :locals which contains the locals map passed to run.
  def sandboxed_methods(*allowed_methods)
    _sb_allowed_methods_map = {}
    allowed_methods.each { |meth|
      _sb_allowed_methods_map[meth.to_s.intern] = true
    }

    define_method :_sbm do |meth, sandbox_context, *args|
      if _sb_allowed_methods_map[meth]
        self.set_sandbox_context(sandbox_context) if self.respond_to?(:set_sandbox_context)
        begin
          self.__send__(meth, *args)
        rescue Exception=>e
          raise "Error calling #{meth}: #{e.message}"
        end
      else
        puts _sb_allowed_methods_map.inspect if $DEBUG
        raise SandboxedErb::MissingMethodError, "Unknown method '#{meth}' on object '#{self.class.name}'"
      end
    end
  end
  
  
  #Shortcut to allow everything except a few methods
  #
  #This will not include any superclass methods unless  include_superclasses = true
  #
  #Example 
  # class SomeClass
  #   not_sandboxed_methods :unsafe_method
  #   def some_method
  #     "this is ok to call"
  #   end
  #   def unsafe_method
  #     "this is NOT ok to call"
  #   end
  # end
  def not_sandboxed_methods(include_superclasses = false, allowed_mixins=[], *disallowed_methods)

    __the_methods_to_check = public_instance_methods(false)
    if include_superclasses
      clz = self.superclass
      while !clz.nil?
        unless clz == Object
          #puts "#{self.name}: #{clz.name}: #{clz.public_instance_methods(false).inspect}"
          __the_methods_to_check += clz.public_instance_methods(false)
        end
        clz = clz.superclass
      end
      
      if allowed_mixins.length > 0
        #we include any mixins
        for m in self.included_modules
          if allowed_mixins.include?(m)
            #puts "#{self.name}: #{m.name}: #{m.public_instance_methods(false).inspect}"
            __the_methods_to_check += m.public_instance_methods(false)
          end
        end
      end
    end
    
    __the_methods_to_check << "nil?".intern
    
    __the_methods_to_check.uniq!
    
    unless disallowed_methods.nil? || disallowed_methods.length == 0
      not_bang = false
      if disallowed_methods.include?(:bang_methods) #just remove all xxx! methods that modify in place
        __the_methods_to_check.reject! { |meth| meth.to_s[-1, 1] == "!"}
        not_bang = true
      end
      unless not_bang || disallowed_methods.length > 1
        __the_methods_to_check.reject! { |meth| disallowed_methods.include?(meth)}
      end
    end
    
    #puts "#{self.name}: #{__the_methods_to_check.inspect}"
     
    sandboxed_methods(*__the_methods_to_check)
    
    
    
  end

end

