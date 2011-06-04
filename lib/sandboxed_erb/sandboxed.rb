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
    
    #we need to lock this class down... any 
    self.instance_methods.each do |sym|
      old_warning_level = $-w  
      $-w = nil #undefining some methods give warning.. lets suppress them...
      sym = sym.intern
      undef_method sym unless [:method_missing, :_sbm].include?(sym)
      $-w = old_warning_level
    end
 
  end
end
