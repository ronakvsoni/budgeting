class Interface
  attr_reader :prompt
  attr_accessor :exit, :user

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)
    @exit = false
  end

  #Instance methods for interacting with the Interface object

  #TODO: Set this up so it clears the prompt
  def open
    prompt.say('Let\'s clean this up first...')
    sleep 1
    if Gem.win_platform?
      system 'cls'
    else
      system 'clear'
    end

    open_choice = prompt.select('Hi! Are you new here?', cycle: true) do |s|
      s.choice 'Brand new!', -> { 'create_user' }
      s.choice 'Nope! Sign me in, please.', -> { 'sign_in' }
      s.choice 'Exit.', -> { 'close' }
    end

    self.send(open_choice)
  end

  def close
    self.exit = true
  end

  def create_user
    prompt.say('Welcome!') #TODO: Add color to this later
    first_name = prompt.ask('Please say your first name:', modify: :collapse)
    last_name = prompt.ask('Great, and your last name?', modify: :collapse)

    email_quest = 'Thanks! Now your email address:'
    email_verified = false
    until email_verified do
      email = prompt.ask(email_quest, validate: :email)
      email_quest = 'Oh, sorry! Please enter your email address again:'
      email_verified = prompt.select("Great! I have your email as #{email}. Is that right?", cycle: :true) do |s|
        s.choice 'Yep!', true
        s.choice 'No, that isn\'t right.', false
      end
    end

    self.user = User.new(first_name: first_name, last_name: last_name, email: email)

    prompt.say('Okay! Here\'s what we\'ve got:')
    prompt.say("Name: #{self.user.first_name} #{self.user.last_name}")
    prompt.say("Email: #{self.user.email}")
    puts ''
    
    sleep 1

    self.close
  end

  def sign_in
    ap 'Sign In here, please sign here.'

    self.close
  end

  def art_of_budgeting
    logo = File.read('./cli/budgeting.txt')
    puts logo
  end
end