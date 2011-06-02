module SandboxedErb
  class Sandboxed
    
    #a method that is not available has been called...
    def method_missing(meth_id, *args)
      raise SandboxedErb::MissingMethodError, "Unknown method '#{meth_id}' on object '#{@object.class.name}'"
    end
 
  end
end
