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
    
    sandbox_class = eval "class #{self.to_s}::SandboxClass < SandboxedErb::Sandboxed; self; end"
    define_method :to_sandboxed do
      sandbox_class.new(self)
    end
    sandbox_class.class_eval do
      def initialize(object)
        @object = object
      end
      allowed_methods.each do |sym|
        define_method sym do |*args|
          begin
            @object.send(sym, *args)
          rescue Exception=>e
            raise SandboxedErb::RuntimeError, "Error calling #{sym} on class #{@object.class.name}: #{e.message}"
          end
        end
      end
    end
  end

end

class Object
  #this method is called by converted script to get a sandbox proxy... will return a NotSandboxed object if it does not support sandboxing
  def _sbm
    begin
      self.to_sandboxed
    rescue
      #must not support sandboxing....
      raise SandboxedErb::RuntimeSecurityError, "#{self.class.name} is not accessable"
    end
  end
end
