module TransactionInterface
  def add_transaction(p = {})
    self.system_clear

    bank_account = session_focus(:bank_account)
    budget = session_focus(:budget) #used to grab the expenses for this budget

    amount = prompt.ask('How much was the transaction for?')

    expenses = Expense.all
    if expenses.empty?
      expense_select = prompt.select('You haven\'t added any expenses to this budget - make a new one?') do |s|
        s.choice 'Good idea, let\'s do that.', true
        s.choice 'On second thought, I\'d like to go back.', false
      end

      expense_select ? self.open_window('add_transaction') : self.open_window('view_bank_account', bank_account_id: bank_account.id)
    else
      expense_select = prompt.select('Which expense was this transaction for?') do |s|
        expenses.each { |expense| s.choice "#{expense.title}", expense.id }
        s.choice 'I don\'t see it - make me a new one.', true
        s.choice 'Never mind, go back.', false
      end

      if !expense_select
        self.open_window('view_bank_account', bank_account_id: bank_account.id)
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
        # create_expense goes here
      end
    end
  end

  def view_transactions(p = {})
    bank_account = session_focus(:bank_account)

    focus(transaction: nil)

    self.system_clear

    line = '-----------------------------------'
    transaction_header = "Bank Account: #{bank_account.name}\n#{line}"

    transaction_log = { 'Go back.' => false }

    bank_account.transactions.each do |transaction|
      transaction_log[transaction.display] = transaction.id
    end

    #Look at setting this up so every page_length entries is a back button
    transaction_select = prompt.select(transaction_header, transaction_log, per_page: 15)

    !!transaction_select ? self.open_window('edit_transaction', transaction_id: transaction_select) : open_window('view_bank_account', bank_account_id: bank_account.id)
  end

  def edit_transaction(p = {})
    transaction = Transaction.find(p[:transaction_id])

    focus(transaction: transaction)

    self.system_clear

    prompt.say("Edit Transaction - (#{transaction.id}) - Amount: #{transaction.amount} - From: #{transaction.expense.title}")
    menu_select = prompt.select('What would you like to update?') do |s|
      s.choice 'The amount.', 'edit_transaction_amount'
      s.choice 'The expense.', 'edit_transaction_expense'
      s.choice 'Let\'s delete this transaction.', 'delete_transaction'
      s.choice 'Never mind, show me the transaction log again.', false
    end

    !!menu_select ? self.open_window(menu_select) : self.open_window('view_transactions')
  end

  def edit_transaction_amount(p = {})
    transaction = session_focus(:transaction)

    amount = prompt.ask('What would you like to change the amount to?')
    prompt.say('Cool. Just a sec...')
    transaction.update(amount: amount)

    sleep 1

    prompt.say('Done!')

    sleep 1

    self.open_window('edit_transaction', transaction_id: transaction.id)
  end

  def edit_transaction_expense(p = {})
    transaction = session_focus(:transaction)
    expenses = Expense.all
    
    expense_select = prompt.select('Which expense was this transaction for?') do |s|
      expenses.each { |expense| s.choice "#{expense.title}", expense.id }
      s.choice 'I don\'t see it - make me a new one.', true
      s.choice 'Never mind, go back.', false
    end

    if !expense_select
      self.open_window('edit_transaction', transaction_id: transaction.id)
    elsif expense_select.class == Integer
      prompt.say('Got it. Updating the transaction...')
      transaction.update(expense_id: expense_select)
      
      sleep 1

      prompt.say('Done!')

      sleep 1

      self.open_window('edit_transaction', transaction_id: transaction.id)
    else
      # create_expense goes here
    end
  end

  def delete_transaction(p = {})
    transaction = session_focus(:transaction)

    prompt.warn('Careful! Once I delete this, I can\'t bring it back.')
    delete_confirm = prompt.yes?('Are you sure you want to delete this transaction?')
    if delete_confirm
      bank_account_id = transaction.bank_account_id
      transaction.destroy
      focus(transaction: nil)
      prompt.say('Done!')

      sleep 1

      self.open_window('view_transactions')
    else
      self.open_window('edit_transaction', transaction_id: transaction.id)
    end
  end 
end