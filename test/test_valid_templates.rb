require File.expand_path('../helper', __FILE__)

class TestValidTemplates < Test::Unit::TestCase
  
  should "allow for loop" do
    str_template = "<%for i in 0..3 do %><%=i%><%end%>"
    
    
    template = SandboxedErb::Template.new
    result = template.compile(str_template)

    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "0123", result
  end
  
  should "allow whole loop" do
    str_template = "<%
    i=0
    while i <= 3 do %><%=i%><% i+=1
    end%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)

    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "0123", result
  end
  
  
  should "allow if statement" do
    str_template = "<% 
    i=0
    if i > 10 %>1<%else%>2<%end%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)

    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "2", result
  end
  
  should "allow extended conditions" do
    str_template = "<% 
    i=5
    if i > 10 && i < 300 %>1<%elsif i > 100 || i == 5%>2<%end%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)

    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "2", result
  end
  
  should "allow unless statement" do
    str_template = "<% 
    i=0
    unless i > 10 %>1<%else%>2<%end%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)
    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "1", result
  end
  
  should "allow case statement" do
    str_template = "<% 
    i=3
    case i
    when 0...3: %>1<%
    when 4..100: %>2<%
    when 2...4:%>3<%
    else %>4<%
    end%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)
    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "3", result
  end
  
  should "allow defining array" do
    str_template = "<% 
    test = [1,2,3,4]
    %><%=test[2]%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)
    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "3", result
  end
  
  should "allow setting array value" do
    str_template = "<% 
    test = [1,2,3,4]
    test[2] = 8
    %><%=test[2]%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)
    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "8", result
  end
  
  should "allow defining hash" do
    str_template = "<% 
    test = {1=>2,2=>3,3=>4,4=>5}
    %><%=test[2]%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)
    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "3", result
  end
  
  should "allow setting hash value" do
    str_template = "<% 
    test = {1=>2,2=>3,3=>4,4=>5}
    test[2] = 8
    %><%=test[2]%>"

    template = SandboxedErb::Template.new
    result = template.compile(str_template)
    assert_equal nil, template.get_error
    
    assert_equal true, result
    
    result = template.run(nil,{})
    
    assert_equal nil, template.get_error
    assert_equal "8", result
  end
  
  
end
