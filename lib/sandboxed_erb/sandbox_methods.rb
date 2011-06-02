

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
