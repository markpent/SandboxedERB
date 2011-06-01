module SandboxedErb
  class Sandboxed
    
    attr_writer :context

    #a method that is not available has been called...
    def method_missing(meth_id, *args)
      SandboxedErb::NotSandboxed.new("Unknown method #{meth_id} on object #{@object.class.name}")
    end
 
  end
end
