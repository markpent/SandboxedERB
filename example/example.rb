require 'rubygems'

gem 'faker'
gem 'partialruby'
gem 'ruby_parser'

require 'date'
require 'faker'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'sandboxed_erb'


require 'controller.rb'
require 'note.rb'
require 'users.rb'


#an example helper to make functions available to the template... 
module ExampleHelper
  def link_to(title, href)
    #silly example, but it shows how the mixins have access to the @controller context as an instance variable
    if href.index(":").nil?
      "<a href=\"#{@controller.base_url}/#{href}\">#{title}</a>"
    else
      "<a href=\"#{href}\">#{title}</a>"
    end
  end
  
  def format_date(date, format)
    if format == :short_date
      date.strftime("%d %b %Y %H:%M")
    else
      "unknown format: #{format}"
    end
  end
end


#we will load both templates up and output them...

listing_sbhtml = File.open('listing.sbhtml') { |f| f.read }

notes_sbhtml = File.open('view_notes.sbhtml') { |f| f.read}


controller = Controller.new
users = Users.users(20)
    

listing_template = SandboxedErb::Template.new([ExampleHelper])

if !listing_template.compile(listing_sbhtml)
  puts "Listing: #{listing_template.get_error}"
  exit
end


notes_template = SandboxedErb::Template.new([ExampleHelper])

if !notes_template.compile(notes_sbhtml)
  puts "Notes: #{notes_template.get_error}"
  exit
end




result = listing_template.run({:controller=>controller}, {:users=>users})
if result.nil?
  puts "Listing: #{listing_template.get_error}"
  exit
end

File.open("listing.html", "w") { |f| f.write(result)}

result = notes_template.run({:controller=>controller}, {:user=>users[0], :users=>users})
if result.nil?
  puts "Notes: #{notes_template.get_error}"
  exit
end

File.open("notes.html", "w") { |f| f.write(result)}



