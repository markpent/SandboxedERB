class Users
  
  def self.users(count)
    res = []
    for i in 0...count
      res << User.new(i)
    end
    res
  end
end

class User

  attr_accessor :id
  attr_accessor :first_name
  attr_accessor :last_name
  attr_accessor :email
  attr_accessor :phone
  
  
  sandboxed_methods :id, :first_name, :last_name, :email, :phone, :notes, :url_for
  
  def initialize(id)
    @id = id
    @first_name = Faker::Name.first_name
    @last_name = Faker::Name.last_name     
    @email = Faker::Internet.email(@first_name)
    @phone = Faker::PhoneNumber.phone_number
  end
  
  def set_sandbox_context(context)
    @sandbox_context = context
  end
  
  def notes
    @notes ||= build_notes
  end
  
  def build_notes
    res = []
    for i in 0..(rand * 5 + 1).to_i
      res << Note.new(@sandbox_context[:locals][:users])
    end
    res
  end
  
  def url_for(action)
    if action == :edit
      @sandbox_context[:controller].url_for(:controller=>:users, :action=>:edit, :id=>@id)
    elsif action == :send_message
      @sandbox_context[:controller].url_for(:controller=>:users, :action=>:send_message, :id=>@id)
    end
    
  end
end
