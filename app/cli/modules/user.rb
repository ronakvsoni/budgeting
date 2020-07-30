#TODO: Clean this up after removing the phone methods
module UserInterface
  def create_user(p = {})
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
      email_quest = 'Sorry! Please enter your email address again:'
      email_verified = prompt.select("Great! I have your email as #{email}. Is that right?", cycle: :true) do |s|
        s.choice 'Yep!', true
        s.choice 'No, that isn\'t right.', false
      end

      if !!User.find_by(email: email)
        email_verified = false
        prompt.say('Looks like there\'s already a user with that email in our system.')
        sleep 1
      end
    end

    self.user = User.create(first_name: first_name, last_name: last_name, email: email)

    prompt.say('Okay! Here\'s what we\'ve got:')
    prompt.say("Name: #{self.user.first_name} #{self.user.last_name}")
    prompt.say("Email: #{self.user.email}")
    puts ''
    
    sleep 1

    prompt.say('Siging you in...')

    sleep 2

    self.open_window('user_dashboard')
  end

  def sign_in(p = {})
    email_quest = 'Welcome back! Please enter your email:'
    exit_string = 'Press enter to go back.'
    email_verified = false

    #Check if the email exists in the database
    until email_verified do
      email = prompt.ask(email_quest, default: exit_string)
      email_quest = 'Sorry! I can\'t find you by that email. Try again?'

      break if email == exit_string

      email_verified = !!User.find_by(email: email.downcase) #TODO: Make this a User.emails.include? check
    end

    if email_verified
      #TODO, STRETCH: Password-verified user fetch. This will work with literally anything right now.
      until self.user do
        pw_verified = prompt.mask('Please enter your password:')

        self.user = User.find_by(email: email)
      end
        prompt.say('Signing you in...')
        sleep 1
        self.open_window('user_dashboard')
    else
      self.open_window('main_menu')
    end
  end

  def sign_out(p = {})
    prompt.say('Signing you out...')
    self.user = nil

    sleep 1

    self.open_window('main_menu')
  end

  def user_dashboard(p = {})
    self.system_clear

    self.reset_focus

    menu_select = prompt.select("Hi, #{self.user.first_name}! What would you like to do next?") do |s|
      s.choice 'Show me my budgets.', 'select_budget_menu'
      s.choice 'I\'d like to update my user profile.', 'edit_user'
      s.choice 'Sign me out.', 'sign_out'
    end

    self.open_window(menu_select)
  end

  def edit_user(p = {})
    self.system_clear
    prompt.say('Here\'s your profile!')
    prompt.say("Name: #{self.user.first_name} #{self.user.last_name}")
    prompt.say("Email: #{self.user.email}")
    # !!self.user.phone ? prompt.say("Phone: #{self.user.phone}") : prompt.say('Looks like we don\'t have a phone number!')
    puts ''

    menu_select = prompt.select('What would you like to change?') do |s|
      s.choice 'My name.', 'edit_user_name'
      s.choice 'My email address.', 'edit_user_email'
      # s.choice 'My phone number.', 'edit_user_phone'
      s.choice 'I want to delete my account.', 'delete_user'
      s.choice 'Never mind, take me back.', 'user_dashboard'
    end

    self.open_window(menu_select)
  end

  def delete_user(p = {})
    first_select = prompt.select('Oh! Sorry to hear that. Are you sure?') do |s|
      s.choice 'On second thought...', false
      s.choice 'I\'m sure.', true
    end

    if first_select
      prompt.warn('You\'re positive? This will delete your user and all associated data immediately.')
      prompt.warn('This action can\'t be undone.')
      last_select = prompt.select('Delete your user profile and all data?') do |s|
        s.choice 'No.', false
        s.choice 'Yes.', true
      end

      if last_select
        prompt.warn('Okay! Sorry to see you go. Stand by for disintegration.')

        sleep 3

        self.user.destroy
        self.open_window('sign_out')
      else
        prompt.say('Phew! You were scaring me. To the dashboard!')
        sleep 2
        self.open_window('user_dashboard')
      end
    else
      prompt.say('Good call. Let\'s head back to the dashboard.')
      sleep 2
      self.open_window('user_dashboard')
    end
  end

  def edit_user_name(p = {})
    prompt.say('I\'ve got my whiteout ready:')
    prompt.say("First name: #{self.user.first_name}")
    prompt.say("Last name: #{self.user.last_name}")

    menu_select = prompt.select('Would you like to change your first name or your last name?') do |s|
      s.choice 'My first name.', 'first_name'
      s.choice 'Last, please.', 'last_name'
    end

    new_name = prompt.ask('Sure thing! What would you like to change it to?')
    prompt.say('Strong name. Updating...')

    self.user.send("#{menu_select}=", new_name)
    self.user.save

    sleep 1

    prompt.say("Done! Your name is now #{self.user.first_name} #{self.user.last_name}.")

    done = prompt.select('Finished here?') do |s|
      s.choice 'Yes, thank you.', true
      s.choice 'No, I want to change something else.', false
    end

    if done
      prompt.say('Glad to be of help! Dashboard coming up...')
      sleep 1
      self.open_window('user_dashboard')
    else
      prompt.say('Getting creative? I like it.')
      sleep 1
      self.open_window('edit_user_name')
    end
  end

  def edit_user_email(p = {})
    prompt.say("Your email address is #{self.user.email}.")
    
    email_quest = 'What do you want to change it to?'
    email_verified = false
    until email_verified do
      email = prompt.ask(email_quest) do |a|
        a.validate :email
        a.modify :down
      end
      email_quest = 'Sorry! Please enter a different email:'
      email_verified = prompt.select("Great! I have your email as #{email}. Is that right?", cycle: :true) do |s|
        s.choice 'Yep!', true
        s.choice 'No, that isn\'t right.', false
      end

      if !!User.find_by(email: email)
        email_verified = false
        prompt.say('Looks like there\'s already a user with that email in our system.')
        sleep 1
      end
    end

    prompt.say('Updating...')

    self.user.email = email
    self.user.save

    sleep 1

    prompt.say('Done!')

    sleep 1

    self.open_window('edit_user')
  end

  # def edit_user_phone(direct = false)
  #   if direct
  #     phone = prompt.ask('What would you like to change it to?', default: 'Leave this blank to delete it.')

  #     prompt.say('Updating...')

  #     self.user.phone = phone
  #     self.user.save

  #     sleep 1

  #     prompt.say('Done!')

  #     sleep 1

  #     self.open_window('edit_user')
  #   end

    
  #   !!self.user.phone ? prompt.say("Phone: #{self.user.phone}") : prompt.say('Looks like we don\'t have a phone number!')
  #   menu_select = prompt.select('What would you like me to do?') do |s|
  #     s.choice 'Change my phone number.', true
  #     s.choice 'Never mind, take me back.', false
  #   end

  #   if menu_select
  #     self.edit_user_phone(true)
  #   else
  #     self.edit_user
  #   end
  # end
end