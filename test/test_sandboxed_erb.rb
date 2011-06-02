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
    
    result = template.run(nil, {})
    
    assert_equal "Hello World, 1 + 1 = 2.", result
  end
  
  should "be able to access local variables" do
    data = { :key1 =>"A", :key2=>"B" }
    str_template = "the value for key1 is <%=data[:key1] %> and key2 is <%=data[:key2] %>"
    template = SandboxedErb::Template.new
    template.compile(str_template)
    result = template.run(nil, {:data=>data})
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
    
    
    assert_raise(SandboxedErb::MissingMethodError) {
      tc.not_ok_to_call.to_s
    } 
    
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
    result = template.run(nil, {:tc=>TestClass.new})
    
    assert_equal "ok_to_call = A", result
  end
  

  should "report insecure call during run: method" do
    str_template = "i shoudl not be
    able to get
    <%
    eval('something')
    %>
    "
    template = SandboxedErb::Template.new
    assert_equal true, template.compile(str_template)
    assert_equal nil, template.run(nil, {})
    
    assert_equal "Error on line 4: Unknown method: eval", template.get_error
  end
  
  
  should "allow mixins" do
    
    module MixinTest
      def test_mixin_method(val)
        "TEST #{val}"  
      end
    end
    
    str_template = "mixin = <%= test_mixin_method(1) %>"
    template = SandboxedErb::Template.new([MixinTest])
    assert_equal true, template.compile(str_template)
    result = template.run(nil, {})
    
    assert_equal "mixin = TEST 1", result

  end
  
  should "allow multiple mixins" do
    
    module MixinTest1
      def test_mixin_method1(val)
        "TEST #{val}"  
      end
    end
    
    module MixinTest2
      def test_mixin_method2(val)
        "TEST #{val}"  
      end
    end
    
    str_template = "mixin = <%= test_mixin_method1(test_mixin_method2('A')) %>"
    template = SandboxedErb::Template.new([MixinTest1, MixinTest2])
    assert_equal true, template.compile(str_template)
    result = template.run(nil, {})
    
    assert_equal "mixin = TEST TEST A", result

  end
  
  should "access context objects from mixins" do
    
    module MixinTest
      def test_mixin_method
        "TEST #{@controller.some_value}"  
      end
    end
    
    class FauxController
      def some_value
        "ABC"  
      end
    end
    
    faux_controller = FauxController.new
    
    str_template = "mixin = <%= test_mixin_method %>"
    template = SandboxedErb::Template.new([MixinTest])
    assert_equal true, template.compile(str_template)
    result = template.run({:controller=>faux_controller}, {})
    
    assert_equal "mixin = TEST ABC", result

  end
  
  
  
  
end
