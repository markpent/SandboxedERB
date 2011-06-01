module SandboxedErb
  class NotSandboxed
    def initialize(error)
      @error = error
    end
    
    def to_sandboxed
      self
    end
    
    #finally report the error
    def to_s
      @error
    end
    
    #called a method... just retun itself
    def method_missing(methId, *args)
      self
    end
  end

end
