require File.expand_path('../helper', __FILE__)

class TestCompileErrors < Test::Unit::TestCase
  should "report insecure call during compile: global" do
    str_template = "i shoudl not be
    able to get
    global: <%= $some_global_value %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot access global variables in a template", template.get_error
  end
  
  should "report insecure call during compile: global asign" do
    str_template = "i shoudl not be
    able to get
    global: <%= $some_global_value = 10 %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot assign global variables in a template", template.get_error
  end
  
  should "report insecure call during compile: const" do
    str_template = "i shoudl not be
    able to get
    global: <%= SOME_CONST %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot access a constant in a template", template.get_error
  end
  
  should "report insecure call during compile: const assign" do
    str_template = "i shoudl not be
    able to get
    global: <%= SOME_CONST = 10 %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot define a constant in a template", template.get_error
  end
  
  should "report insecure call during compile: def" do
    str_template = "i shoudl not be
    able to get
    <%
    def invalid_func
      
    end
    %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    assert_equal "Line 4: You cannot define a method in a template", template.get_error
  end
  
  should "report insecure call during compile: module def" do
    str_template = "i shoudl not be
    able to get
    <%
    module Not
      def invalid_func
        
      end
    end
    %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 4: You cannot define a module in a template", template.get_error
  end
  
  should "report insecure call during compile: class def" do
    str_template = "i shoudl not be
    able to get
    <%
    class Not
      def invalid_func
        
      end
    end
    %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 4: You cannot define a class in a template", template.get_error
  end
  
  should "report insecure call during compile: member vars" do
    str_template = "i shoudl not be
    able to get
    <%= @test %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot access instance members in a template", template.get_error
  end
  
  should "report insecure call during compile: member var assign" do
    str_template = "i shoudl not be
    able to get
    <% @test = 2 %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_equal "Line 3: You cannot assign instance members in a template", template.get_error
  end
  
  
  should "report insecure call during compile: cvar assign" do
    str_template = "i shoudl not be
    able to get
    <% SomeClass.some_attr = 2 %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    assert_equal "Line 3: You cannot access a constant in a template", template.get_error
  end
  
  
  should "report compile errors" do
    str_template = "i shoudl not be
    able to get
    <%
    for x out of not
    %>
    "
    template = SandboxedErb::Template.new
    assert_equal false, template.compile(str_template)
    
    assert_match /line:4: syntax error/, template.get_error
  end
end
