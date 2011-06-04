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

class Module
  def sandboxed_methods(*allowed_methods)
    
    _sb_allowed_methods_map = {}
    allowed_methods.each { |meth|
      _sb_allowed_methods_map[meth.to_s.intern] = true
    }

    define_method :_sbm do |meth, *args|
      if _sb_allowed_methods_map[meth]
        begin
          self.__send__(meth, *args)
        rescue Exception=>e
          raise "Error calling #{target}: #{e.message}"
        end
      else
        puts _sb_allowed_methods_map.inspect if $DEBUG
        raise SandboxedErb::MissingMethodError, "Unknown method '#{meth}' on object '#{self.class.name}'"
      end
    end
  end
  
  
  #shortcut to allow everything except a few methods
  #this will not include any superclass methods
  #make sure this is called AFTER all methods are defined in the class.
  def not_sandboxed_methods(include_superclasses = false, *disallowed_methods)

    __the_methods_to_check = public_instance_methods(false)
    if include_superclasses
      clz = self.superclass
      while !clz.nil?
        unless clz == Object
          __the_methods_to_check += clz.public_instance_methods(false)
        end
        clz = clz.superclass
      end
    end
    
    
    __the_methods_to_check.uniq!
    
    sandboxed_methods(*__the_methods_to_check)
    
  end

end

