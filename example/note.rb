class Note
  
  attr_accessor :from
  attr_accessor :subject
  attr_accessor :message
  attr_accessor :at
  
  
  sandboxed_methods :from, :subject, :message, :at

  def initialize(all_users)
    @from = all_users[(rand * all_users.length).floor]
    @subject = Faker::Lorem.sentence
    @message = Faker::Lorem.paragraph
    @at = DateTime.now - (rand * 10000)
  end
end
