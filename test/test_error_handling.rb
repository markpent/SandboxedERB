require 'helper'

class TestErrorHandling < Test::Unit::TestCase
  should "handle missing function of object" do
    
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
    assert_equal nil,template.run(nil, {:tc=>TestClass.new})
    assert_equal "Error on line 1: Unknown method 'not_ok_to_call' on object 'TestErrorHandling::TestClass'", template.get_error

  end
  
  should "handle missing functions" do
    

    str_template = "some method = <%=some_method_that_does_not_exist(1) %>"
    template = SandboxedErb::Template.new
    template.compile(str_template)
    assert_equal nil,template.run(nil, {:tc=>TestClass.new})
    
    assert_equal "Error on line 1: Unknown method: some_method_that_does_not_exist", template.get_error

  end
  

  should "report exceptions in mixins" do
    
    module MixinTest1
      def test_mixin_method1(val)
        raise "mixin exception"  
      end
    end

    
    str_template = "mixin = 
    <%= test_mixin_method1('A') %>"
    template = SandboxedErb::Template.new([MixinTest1])
    assert_equal true, template.compile(str_template)
    assert_equal nil, template.run(nil, {})
    
    assert_equal "Error on line 2: Error calling test_mixin_method1: mixin exception", template.get_error

  end

end
