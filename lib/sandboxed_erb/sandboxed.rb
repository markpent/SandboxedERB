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

module SandboxedErb
  class Sandboxed
    
    #a method that is not available has been called...
    def method_missing(meth_id, *args)
      raise SandboxedErb::MissingMethodError, "Unknown method '#{meth_id}' on object '#{@object.class.name}'"
    end
    
    #already sandboxed... just return self
    def _sbm
      self
    end
    
    def _invoke_sbm(sym, args)
      begin
        self.send(target, *args)
      rescue Exception=>e
        raise "Error calling #{target}: #{e.message}"
      end
      
    end
 
  end
end
