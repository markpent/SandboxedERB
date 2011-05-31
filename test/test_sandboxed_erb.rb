require 'helper'

class TestSandboxedErb < Test::Unit::TestCase
  should "compile an erb template" do
    compiled_template = SandboxedErb::Template.new.compile_erb_template("Hello World, 1 + 1 = <%= 1 + 1 %>.")
    assert_equal '_erbout = \'\'; _erbout.concat "Hello World, 1 + 1 = "; _erbout.concat(( 1 + 1 ).to_s); _erbout.concat "."; _erbout', compiled_template
  end
  
  should "sandbox a basic compiled template" do
    compiled_template = '_erbout = \'\'; _erbout.concat "Hello World, 1 + 1 = "; _erbout.concat(( 1 + 1 ).to_s); _erbout.concat "."; _erbout'
    sandboxed_template = SandboxedErb::Template.new.sandbox_code(compiled_template)
  end
  
  should "fully compile a basic template" do
    template = SandboxedErb::Template.new
    template.compile("Hello World, 1 + 1 = <%= 1 + 1 %>.")
  end
  
  should "fully compile and run a basic template" do
    template = SandboxedErb::Template.new
    template.compile("Hello World, 1 + 1 = <%= 1 + 1 %>.")
    
    result = template.run({})
    
    assert_equal "Hello World, 1 + 1 = 2.", result
  end
  
  should "be able to access local variables" do
    data = { :key1 =>"A", :key2=>"B" }
    str_template = "the value for key1 is <%=data[:key1] %> and key2 is <%=data[:key2] %>"
    template = SandboxedErb::Template.new
    template.compile(str_template)
    result = template.run({:data=>data})
    assert_equal "the value for key1 is A and key2 is B", result
  end
end
