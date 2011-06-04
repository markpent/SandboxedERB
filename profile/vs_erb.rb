require '../test/helper.rb'
require 'benchmark'

str_template = <<-EOF
<%
i = 1
%>
<table>
    <tr><th>Name</th><th>Email</th></tr>
    <% for user in users %>
        <tr>
            <td><%=i%>: <%= user.name %></td><td><%= user.email %></td>
        </tr>
        <% i += 1 %>
        <% end %>
</table>
EOF


class User
  
  attr_accessor :name
  attr_accessor :email
  
  sandboxed_methods :name, :email
  
  def initialize()
    @name = 'xxxxx'
    @email = 'yyyyy'    
  end
  
  

end

users = []
for i in 0...100
  users << User.new
end





erb_compiled_template = SandboxedErb::Template.new.compile_erb_template(str_template)


sandbox_compiled_template = SandboxedErb::Template.new

#$DEBUG=true
if !sandbox_compiled_template.compile(str_template)
  puts sandbox_compiled_template.get_error
  exit
end

#$DEBUG=false


erb_result = eval(erb_compiled_template)

sb_result = sandbox_compiled_template.run(nil, {:users=>users})


if sb_result.nil?
  puts sandbox_compiled_template.get_error
  exit
end
      
if erb_result != sb_result
  puts erb_result
  puts sb_result
end

Benchmark.bmbm do |x|
  x.report("eval template") { 100.times do eval(erb_compiled_template); end }
  x.report("sandboxed template")  { 100.times do sandbox_compiled_template.run(nil, {:users=>users}); end }
end
