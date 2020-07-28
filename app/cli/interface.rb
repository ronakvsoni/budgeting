class Interface
  attr_reader :prompt
  attr_accessor :exit, :user, :open_message, :open_choice_1, :open_choice_2

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)
    @open_message = 'Hi! Are you new here?'
    @open_choice_1 = 'Brand new!'
    @open_choice_2 = 'Nope! Sign me in, please.'
    @exit = false
  end

  #Instance methods for interacting with the Interface object

  #Opening menu methods and close for the entire interface
  def open
    prompt.say('Let\'s clean this up first...') #TODO: Maybe remove this, but it's kind of cute.
    sleep 1
    self.clear_screen

    open_choice = prompt.select(open_message, cycle: true) do |s|
      s.choice open_choice_1, -> { 'create_user' }
      s.choice open_choice_2, -> { 'sign_in' }
      s.choice 'Exit.', -> { 'close' }
    end

    self.open_message = 'Welcome back! Please select an option:'
    self.open_choice_1 = 'Create a new account, please.'
    self.open_choice_2 = 'Sign me in!'

    self.send(open_choice)
  end

  def close
    self.clear_screen
    prompt.say('Bye for now!')
    self.exit = true
  end

  def clear_screen
    if Gem.win_platform?
      system 'cls'
    else
      system 'clear'
    end
  end

  #Create user and sign in methods
  def create_user
    prompt.say('Welcome!') #TODO: Add color to this later
    first_name = prompt.ask('Please say your first name:', modify: :collapse)
    last_name = prompt.ask('Great, and your last name?', modify: :collapse)

    email_quest = 'Thanks! Now your email address:'
    email_verified = false
    until email_verified do
      email = prompt.ask(email_quest) do |a|
        a.validate :email
        a.modify :down
      end
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
    email_quest = 'Welcome back! Please enter your email:'
    exit_string = 'Press enter to go back.'
    email_verified = false

    #Check if the email exists in the database
    until !!email_verified do
      email = prompt.ask(email_quest, default: exit_string)
      email_quest = 'Sorry! I can\'t find you by that email. Try again?'

      break if email == exit_string

      email_verified = !!User.find_by(email: email.downcase)
    end

    if email_verified
      #TODO, STRETCH: Password-verified user fetch. This will work with literally anything right now.
      until self.user do
        pw_verified = prompt.mask('Please enter your password:')

        self.user = User.find_by(email: email)
      end
        prompt.say('Signing you in...')
        sleep 1
        #TODO: Add sign-in to main menu here
    end
  end

  #User menu methods

  def art_of_budgeting
    logo = File.read('./cli/budgeting.txt')
    puts logo
  end
end