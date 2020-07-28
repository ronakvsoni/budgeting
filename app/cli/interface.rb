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
    logo = File.open('./app/cli/budgeting.txt')
    logo = logo.readlines.map(&:strip)
    logo.each { |line| puts line }
    sleep 3
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

    prompt.say('You\'re all set. Go ahead and sign in.')

    sleep 2

    self.open
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
        self.select_budget_menu
    end
  end

  #User menu methods

  #Budget menus
  def select_budget_menu
    budgets = self.user.budgets
    if budgets.empty?
      go = prompt.select('Looks like you have no budgets! Ready to create one?') do |s|
        s.choice 'Yeah, let\'s do it!', true
        s.choice 'Not right now! Let\'s go back.', false
      end

      go ? self.create_budget : self.open
    else
      budget_id = prompt.select('Okay, I found these budgets:') do |s|
        self.user.budgets.each { |budget| s.choice budget.name, budget.id }
        s.choice 'I\'d like to create a new budget, please!', false
      end

      !!budget_id ? self.view_budget(budget_id) : self.create_budget
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
    prompt.say("Name: #{budget.name}     Created: #{budget.created_at}     Last Updated: #{budget.updated_at}")

    menu_select = prompt.select('Let me know what you\'d like to see:') do |s|
      s.choice 'Wallet', 'wallet'
      s.choice 'Options, please!', 'edit_budget'
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
    self.close
  end
end