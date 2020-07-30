require_all './app/cli/modules/'
#TODO: Make expenses searchable by name or category

class Interface
  attr_reader :prompt
  attr_accessor :session, :user

  include BankAccountMethods
  include BudgetMethods
  include UserMethods

  def initialize
    @prompt = TTY::Prompt.new(enable_color: true)
  end
  
  #Start a session with this instance of the Interface
  def new_session
    self.system_clear
    self.session = {
      #When this is true, the session will quit
      quit: false,

      #The user for the current session
      user: nil,

      #These tags tell the session which object to focus
      focus: {
        budget: nil,
        category: nil,
        expense: nil,
        bank_account: nil,
        transaction: nil
      },

      #Used for opening various windows - initializes with a first-time main menu
      window: 'main_menu',
      args: { first: true }
    }

    until self.session[:quit] do
      self.send(self.session[:window], self.session[:args])
    end

    self.system_clear
    prompt.say('Bye for now!')
  end

  #Quit a session
  def quit_session
    self.session[:quit] = true
  end

  #Open a window
  def open_window(window, args = {})
    self.session[:window], self.session[:args] = window, args
  end

  #Set the focus for a series of windows
  def focus(p = {})
    p.each { |k, v| self.session[:focus][k] = v }
  end

  #Grab a current focus by symbol
  def session_focus(sym)
    self.session[:focus][sym]
  end

  #Clear the window
  def system_clear
    system (Gem.win_platform? ? 'cls' : 'clear')
  end

  #Opening art
  def art_of_budgeting
    self.system_clear
    logo = File.read('./app/cli/budgeting.txt')
    puts logo
    sleep 5
  end

  #Main menu
  def main_menu(p = {})
    self.system_clear

    if p[:first]
      open_message = 'Hi! Are you new here?'
      open_choice_1 = 'Brand new!'
      open_choice_2 = 'Nope! Sign me in, please.'
    else
      open_message = 'Welcome back! Please select an option:'
      open_choice_1 = 'Create a new account, please.'
      open_choice_2 = 'Sign me in!'
    end

    open_choice = prompt.select(open_message, cycle: true) do |s|
      s.choice open_choice_1, 'create_user'
      s.choice open_choice_2, 'sign_in'
      s.choice 'Exit.', false
    end

    !open_choice ? self.quit_session : self.open_window(open_choice)
  end

  #Modules past here


  def add_transaction(p = {})
    self.system_clear

    bank_account = session_focus(:bank_account)

    amount = prompt.ask('How much was the transaction for?')

    expenses = Expense.all
    if expenses.empty?
      expense_select = prompt.select('You haven\'t added any expenses to this budget - make a new one?') do |s|
        s.choice 'Good idea, let\'s do that.', true
        s.choice 'On second thought, I\'d like to go back.', false
      end

      expense_select ? self.add_transaction(bank_account.id) : self.view_bank_account(bank_account.id)

    else
      expense_select = prompt.select('Which expense was this transaction for?') do |s|
        expenses.each { |expense| s.choice "#{expense.title}", expense.id }
        s.choice 'I don\'t see it - make me a new one.', true
        s.choice 'Never mind, go back.', false
      end

      if !expense_select
        self.view_bank_account(bank_account.id)
      elsif expense_select.class == Integer
        prompt.say('Found it. Logging the transaction...')
        Transaction.create(amount: amount, bank_account_id: bank_account.id, expense_id: expense_select)

        sleep 1

        add_another = prompt.yes?('Do you want to add another transaction?')
        
        if add_another
          prompt.say('Let\'s keep this rolling, then!')

          sleep 1

          self.open_window('add_transaction')
        else
          self.open_window('view_bank_account', bank_account_id: bank_account.id)
        end
      else
        self.open_window('add_transaction') # This will turn into create_expense later
      end
    end
  end

  def view_transactions(p = {})
    bank_account = session_focus(:bank_account)

    self.system_clear

    line = '-----------------------------------'
    transaction_header = "Bank Account: #{bank_account.name}\n#{line}"

    transaction_log = { 'Go back.' => false }

    bank_account.transactions.each do |transaction|
      transaction_log[transaction.display] = transaction.id
    end

    #Look at setting this up so every page_length entries is a back button

    transaction_select = prompt.select(transaction_header, transaction_log, per_page: 15)

    !!transaction_select ? self.edit_transaction(transaction_select) : view_bank_account(bank_account.id)
  end

  def edit_transaction(transaction_id)
    transaction = Transaction.find(transaction_id)

    self.system_clear

    prompt.say("Edit Transaction - (#{transaction.id}) - Amount: #{transaction.amount} - From: #{transaction.expense.title}")
    menu_select = prompt.select('What would you like to update?') do |s|
      s.choice 'The amount.', 'edit_transaction_amount'
      s.choice 'The expense.', 'edit_transaction_expense'
      s.choice 'Let\'s delete this transaction.', 'delete_transaction'
      s.choice 'Never mind, show me the transaction log again.', false
    end

    !!menu_select ? self.send(menu_select, transaction.id) : self.view_transactions(transaction.bank_account.id)
  end

  def edit_transaction_amount(transaction_id)
    transaction = Transaction.find(transaction_id)

    amount = prompt.ask('What would you like to change the amount to?')
    prompt.say('Cool. Just a sec...')
    transaction.update(amount: amount)

    sleep 1

    prompt.say('Done!')

    sleep 1

    self.edit_transaction(transaction_id)
  end

  def edit_transaction_expense(transaction_id)
    transaction = Transaction.find(transaction_id)
    expenses = Expense.all
    
    expense_select = prompt.select('Which expense was this transaction for?') do |s|
      expenses.each { |expense| s.choice "#{expense.title}", expense.id }
      s.choice 'I don\'t see it - make me a new one.', true
      s.choice 'Never mind, go back.', false
    end

    if !expense_select
      self.view_bank_account(bank_account_id)
    elsif expense_select.class == Integer
      prompt.say('Got it. Updating the transaction...')
      transaction.update(expense_id: expense_select)
      
      sleep 1

      prompt.say('Done!')

      sleep 1

      self.edit_transaction(transaction_id)
    else
      self.edit_transaction_expense(transaction_id) # This will turn into create_expense later
    end
  end

  def delete_transaction(transaction_id)
    transaction = Transaction.find(transaction_id)

    prompt.warn('Careful! Once I delete this, I can\'t bring it back.')
    delete_confirm = prompt.yes?('Are you sure you want to delete this transaction?')
    if delete_confirm
      bank_account_id = transaction.bank_account_id
      transaction.destroy
      prompt.say('Done!')

      sleep 1

      self.view_transactions(bank_account_id)
    else
      self.edit_transaction(transaction_id)
    end
  end
end
