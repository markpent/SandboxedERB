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
  
  should "be able to sandbox a class" do
    
    class TestClass
      sandboxed_methods :ok_to_call
      
      def ok_to_call
        "A"
      end
      
      def not_ok_to_call
        "B"
      end
    end
    
    tc = TestClass.new._sbm
    assert_equal "A", tc.ok_to_call
    assert_match /Unknown method not_ok_to_call on object/, tc.not_ok_to_call.to_s
    
  end
  
  
  should "be able to access sandboxed class in template" do
    
    class TestClass
      sandboxed_methods :ok_to_call
      
      def ok_to_call
        "A"
      end
      
      def not_ok_to_call
        "B"
      end
    end
    
    str_template = "ok_to_call = <%=tc.ok_to_call %>"
    template = SandboxedErb::Template.new
    template.compile(str_template)
    result = template.run({:tc=>TestClass.new})
    
    assert_equal "ok_to_call = A", result
  end
  
  should "handle missing function gracefully" do
    
    class TestClass
      sandboxed_methods :ok_to_call
      
      def ok_to_call
        "A"
      end
      
      def not_ok_to_call
        "B"
      end
    end
    
    str_template = "not_ok_to_call = <%=tc.not_ok_to_call.some_other_thingo.and_this %>"
    template = SandboxedErb::Template.new
    template.compile(str_template)
    result = template.run({:tc=>TestClass.new})
    
    assert_match /not_ok_to_call = Unknown method not_ok_to_call on object/, result

  end
  
  should "report insecure call during compile: global" do
    str_template = "i shoudl not be
    able to get
    global: <%= $some_global_value %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot access global variables in a template", template.get_error
  end
  
  
end
