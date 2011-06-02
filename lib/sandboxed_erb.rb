require "erb"
require "partialruby"
require "sandboxed_erb/template"
require "sandboxed_erb/tree_processor"
require "sandboxed_erb/sandboxed"
require "sandboxed_erb/sandbox_methods"
require "sandboxed_erb/system_mixins"


module SandboxedErb
  class Error < ::StandardError; end
  
  class CompileError < Error; end
  class CompileSecurityError < Error; end
  class RuntimeError < Error; end
  class RuntimeSecurityError < Error; end
  class MissingMethodError < Error; end
end