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
  def main_menu
    self.system_clear

    open_choice = prompt.select(open_message, cycle: true) do |s|
      s.choice open_choice_1, 'create_user'
      s.choice open_choice_2, 'sign_in'
      s.choice 'Exit.', 'close'
    end

    self.open_message = 'Welcome back! Please select an option:'
    self.open_choice_1 = 'Create a new account, please.'
    self.open_choice_2 = 'Sign me in!'

    self.send(open_choice)
  end

  def close
    self.system_clear
    prompt.say('Bye for now!')
    self.exit = true
  end

  def system_clear
    if Gem.win_platform?
      system 'cls'
    else
      system 'clear'
    end
    print ''
  end

  def art_of_budgeting
    self.system_clear
    logo = File.read('./app/cli/budgeting.txt')
    puts logo
    sleep 5
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

    self.user_dashboard
  end

  def sign_in
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
        self.user_dashboard
    else
      self.main_menu
    end
  end

  def sign_out
    prompt.say('Sure thing. Signing you out...')
    self.user = nil

    sleep 1

    self.main_menu
  end

  #User menu methods

  #User menus
  def user_dashboard
    self.system_clear

    menu_select = prompt.select("Hi, #{self.user.first_name}! What would you like to do next?") do |s|
      s.choice 'Show me my budgets.', 'select_budget_menu'
      s.choice 'I\'d like to update my user profile.', 'edit_user'
      s.choice 'Sign me out.', 'sign_out'
    end

    self.send(menu_select)
  end

  def edit_user
    self.system_clear
    prompt.say('Here\'s your profile!')
    prompt.say("Name: #{self.user.first_name} #{self.user.last_name}")
    prompt.say("Email: #{self.user.email}")
    !!self.user.phone ? prompt.say("Phone: #{self.user.phone}") : prompt.say('Looks like we don\'t have a phone number!')
    puts ''

    menu_select = prompt.select('What would you like to change?') do |s|
      s.choice 'My name.', 'edit_user_name'
      s.choice 'My email address.', 'edit_user_email'
      s.choice 'My phone number.', 'edit_user_phone'
      s.choice 'I want to delete my account.', 'delete_user'
      s.choice 'Never mind, take me back.', 'user_dashboard'
    end

    self.send(menu_select)
  end

  def delete_user
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
        self.sign_out
      else
        prompt.say('Phew! You were scaring me. To the dashboard!')
        sleep 2
        self.user_dashboard
      end
    else
      prompt.say('Good call. Let\'s head back to the dashboard.')
      sleep 2
      self.user_dashboard
    end
  end

  def edit_user_name
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
      self.user_dashboard
    else
      prompt.say('Getting creative? I like it.')
      sleep 1
      self.edit_user_name
    end
  end

  def edit_user_email
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

    self.edit_user
  end

  def edit_user_phone(direct = false)
    if direct
      phone = prompt.ask('What would you like to change it to?', default: 'Leave this blank to delete it.')

      prompt.say('Updating...')

      self.user.phone = phone
      self.user.save

      sleep 1

      prompt.say('Done!')

      sleep 1

      self.edit_user
    end

    
    !!self.user.phone ? prompt.say("Phone: #{self.user.phone}") : prompt.say('Looks like we don\'t have a phone number!')
    menu_select = prompt.select('What would you like me to do?') do |s|
      s.choice 'Change my phone number.', true
      s.choice 'Never mind, take me back.', false
    end

    if menu_select
      self.edit_user_phone(true)
    else
      self.edit_user
    end
  end

  #Budget menus
  def select_budget_menu(p = {})
    budgets = self.user.budgets
    if budgets.empty?
      go = prompt.select('Looks like you have no budgets! Ready to create one?') do |s|
        s.choice 'Yeah, let\'s do it!', true
        s.choice 'Not right now! Let\'s go back.', false
      end

      go ? self.create_budget : self.user_dashboard
    else
      menu_select = prompt.select('Okay, I found these budgets:') do |s|
        self.user.budgets.each { |budget| s.choice budget.name, budget.id }
        s.choice 'I\'d like to create a new budget, please!', 'create_budget'
        s.choice 'On second thought, dashboard me again.', 'user_dashboard'
      end

      !!(menu_select.class == Integer) ? self.view_budget(menu_select) : self.send(menu_select)
    end
  end

  def create_budget
    name = prompt.ask('First, name your budget:', modify: :collapse)
    prompt.say('Good name! Loading it up...')
    budget = Budget.create(name: name, user_id: self.user.id)
    sleep 2
    self.view_budget(budget.id)
  end

  def view_budget(budget_id)
    self.system_clear

    budget = Budget.find_by(id: budget_id)
    self.user.last_opened_budget = budget_id
    self.user.save
    prompt.say("Name: #{budget.name}     Created: #{budget.created_at}     Last Updated: #{budget.updated_at}")

    menu_select = prompt.select('Let me know what you\'d like to see:') do |s|
      s.choice 'Wallet', 'wallet'
      s.choice 'Options, please!', 'edit_budget'
      s.choice 'Show me all my budgets again?', 'select_budget_menu'
    end

    self.send(menu_select, budget_id)
  end

  def edit_budget(budget_id)
    self.system_clear

    budget = Budget.find_by(id: budget_id)
    prompt.say("Name: #{budget.name}     Created: #{budget.created_at}     Last Updated: #{budget.updated_at}")

    menu_select = prompt.select('What would you like to do?') do |s|
      s.choice 'Let\'s rename this budget.', 'rename_budget'
      s.choice 'I want to delete this budget.', 'delete_budget'
      s.choice 'Wrong turn! Take me back.', 'view_budget'
    end

    self.send(menu_select, budget_id)
  end

  def rename_budget(budget_id)
    budget = Budget.find_by(id: budget_id)

    name = prompt.ask('I didn\'t like that name either. What do you want me to call it now?')

    budget.name = name
    budget.save
    prompt.say("Nice! Renaming this budget to #{name}...")

    sleep 2

    prompt.say('You\'re all set!')

    sleep 1

    self.edit_budget(budget_id)
  end

  def delete_budget(budget_id)
    budget = Budget.find_by(id: budget_id)

    menu_select = prompt.select('Are you sure?') do |s|
      s.choice 'On second thought...', false
      s.choice 'Yes.', true
    end

    if menu_select
      delete_select = prompt.select('Are you super sure? This will delete this budget and all associated transaction information.') do |s|
        s.choice 'That sounds pretty final. I\'ll think about it.', false
        s.choice 'I\'m positive.', true
      end
    end

    if (!menu_select || !delete_select)
      prompt.say('Phew! Talking about deleting budgets always stresses me out.')
      prompt.say('I\'ll send you back to the menu, hold tight.')
      
      sleep 2

      self.edit_budget(budget_id)
    else
      prompt.say('Okay, cover your ears! I\'m about to blow this budget up.')

      #TODO: See if budget.destroy alone gets the job done here
      # budget.bank_accounts.each do |bank_account|
      #   bank_account.transactions.each do |transaction|
      #     transaction.expense.destroy if !!transaction.expense
      #     transaction.destroy
      #   end
      #   bank_account.destroy
      # end

      budget.destroy
  
      sleep 1

      prompt.say('Done! Now go look at your other budgets while I sweep up this dust.')

      sleep 2

      self.system_clear
      self.select_budget_menu
    end

  end

  def wallet(budget_id)
    budget = Budget.find_by(id: budget_id)
    bank_accounts = budget.bank_accounts

    if bank_accounts.length == 0
      add_bank_account = prompt.select('Oh! It\'s empty. Want to add a bank account?') do |s| #Could do a prompt.yes?no? here
        s.choice 'That\'s embarrassing. Sure!', true
        s.choice 'No, not right now.', false
      end

      if add_bank_account
        self.create_bank_account
      else
        prompt.say('Alright, going back.')
        sleep 1
        self.view_budget(budget_id)
      end
    else
      menu_select = prompt.select('Here\'s all of your accounts. Which one do you want to see?') do |s|
        bank_accounts.each { |bank_account| s.choice "#{bank_account.name}", bank_account.id }
        s.choice 'Close this wallet, please.', false
      end

      if !menu_select
        prompt.say('Sure, taking you back.')
        sleep 1
        self.view_budget(budget_id)
      else
        self.view_bank_account(menu_select)
      end
    end
  end

  def create_bank_account(p = {})
    self.select_budget_menu
  end

  def view_bank_account(p = {})
    self.select_budget_menu
  end

end