#add sandboxed method to basic inbuilt objects

class String
  def sandboxed
    self
  end
end

class Fixnum
  def sandboxed
    self
  end
end

class Array
  def sandboxed
    self  
  end
end

class Hash
  def sandboxed
    self  
  end
end

class FalseClass
  def sandboxed
    self  
  end
end

class TrueClass
  def sandboxed
    self  
  end
end
