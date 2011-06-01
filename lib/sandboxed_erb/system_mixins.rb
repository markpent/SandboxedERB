#add sandboxed method to basic inbuilt objects

class String
  def to_sandboxed
    self
  end
end

class Fixnum
  def to_sandboxed
    self
  end
end

class Array
  def to_sandboxed
    self  
  end
end

class Hash
  def to_sandboxed
    self  
  end
end

class FalseClass
  def to_sandboxed
    self  
  end
end

class TrueClass
  def to_sandboxed
    self  
  end
end
