require "rubygems"
require 'liquid'


require '../test/helper.rb'
require 'benchmark'


str_template = <<-EOF
<table>
    <tr><th>Name</th><th>Email</th></tr>
    <% for user in users %>
        <tr>
        <td><%= user.name %></td><td><%= user.email %></td>
        </tr>
    <% end %>
</table>
EOF

ltemplate = <<-EOF
<table>
    <tr><th>Name</th><th>Email</th></tr>
    {% for user in users %}
        <tr>
        <td>{{ user.name }}</td><td>{{ user.email }}</td>
        </tr>
    {% endfor %}
</table>
EOF


class User
  
  attr_accessor :name
  attr_accessor :email
  
  sandboxed_methods :name, :email
  liquid_methods :name, :email
  
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

liquid_template = Liquid::Template.parse(ltemplate)

sandbox_compiled_template = SandboxedErb::Template.new

if !sandbox_compiled_template.compile(str_template)
  puts sandbox_compiled_template.get_error
  exit
end



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

liquid_result = liquid_template.render({'users'=>users})

if liquid_result != sb_result
  puts liquid_result.inspect
  puts sb_result.inspect
end

Benchmark.bmbm do |x|
  x.report("eval template") { 100.times do eval(erb_compiled_template); end }
  x.report("sandboxed template")  { 100.times do sandbox_compiled_template.run(nil, {:users=>users}); end }
  x.report("liquid template") { 100.times do liquid_template.render({'users'=>users}); end }
end
