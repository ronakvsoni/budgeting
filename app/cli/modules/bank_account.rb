module BankAccountInterface
  def wallet(p = {})
    budget = session_focus(:budget)
    bank_accounts = budget.bank_accounts

    focus(bank_account: nil)

    self.system_clear

    if bank_accounts.empty?
      add_bank_account = prompt.select('Oh! This wallet is empty. Want to add a bank account?') do |s|
        s.choice 'That\'s embarrassing. Sure!', true
        s.choice 'No, not right now.', false
      end

      if add_bank_account
        self.open_window('create_bank_account')
      else
        prompt.say('Alright, going back.')
        sleep 1
        self.open_window('view_budget', budget_id: budget.id)
      end
    else
      menu_select = prompt.select('Here\'s all of your accounts. Which one do you want to see?') do |s|
        bank_accounts.each { |bank_account| s.choice "#{bank_account.name}", bank_account.id }
        s.choice 'Add another bank account.', 'create_bank_account'
        s.choice 'Close this wallet, please.', false
        s.choice 'Let\'s go back to the dashboard.', 'user_dashboard'
      end

      if !menu_select
        self.open_window('view_budget', budget_id: budget.id)
      elsif menu_select.class == Integer
        self.open_window('view_bank_account', bank_account_id: menu_select)
      else
        self.open_window(menu_select)
      end
    end
  end

  def create_bank_account(p = {})
    budget = session_focus(:budget)

    bank_name = prompt.ask('Which bank is this account at?')
    name = prompt.ask('Okay, got that down. What do you want to call the account?')
    prompt.say('Easy. Saving this...')
    bank_account = BankAccount.create(bank_name: bank_name, name: name, budget_id: budget.id)

    sleep 2

    balance = prompt.ask('Done! What\'s the starting balance?').to_f
    Transaction.create(amount: balance, bank_account_id: bank_account.id)

    prompt.say('Good place to start!')

    sleep 1

    self.open_window('view_bank_account', bank_account_id: bank_account.id)
  end

  def view_bank_account(p = {})
    self.system_clear

    bank_account = BankAccount.find(p[:bank_account_id])
    focus(bank_account: bank_account)

    prompt.say("Bank: #{bank_account.bank_name}          Name: #{bank_account.name}          Balance: #{bank_account.display_balance}")
    menu_select = prompt.select('What would you like to do?') do |s|
      s.choice 'Add a new transaction.', 'add_transaction'
      s.choice 'See the transaction history.', 'view_transactions'
      s.choice 'Update this bank account.', 'edit_bank_account'
      s.choice 'Go back.', false
      s.choice 'Take me back to my dashboard.', 'user_dashboard'
    end

    !!menu_select ? self.send(menu_select, bank_account.id) : self.wallet(bank_account.budget_id)
  end

  def edit_bank_account(p = {})
    bank_account = session_focus(:bank_account)

    self.system_clear

    prompt.say('Here\'s this account\'s file:')
    prompt.say("Bank: #{bank_account.bank_name}")
    prompt.say("Name: #{bank_account.name}")
    # TODO, STRETCH: Add an option to link a bank account through Plaid API here
    # TODO: Add status to bank account so you can mark one as 'closed'
    menu_select = prompt.select('What would you like to do?') do |s|
      s.choice 'Update the name, please!', 'rename_bank_account'
      s.choice 'Delete this bank account.', 'delete_bank_account'
      s.choice 'Wrong turn! Go back to the wallet.', false
    end

    if !menu_select
      self.open_window('wallet')
    else
      self.open_window(menu_select)
    end
  end

  def rename_bank_account(p = {})
    bank_account = session_focus(:bank_account)

    name = prompt.ask('Okay! What would you like to call it?')
    bank_account.update(name: name)

    prompt.say('Yeah, that is better! Saving it now...')
    sleep 1

    self.open_window('edit_bank_account')
  end

  def delete_bank_account(p = {})
    bank_account = session_focus(:bank_account)

    first_select = prompt.select('Are you sure? This is extremely permanent.') do |s|
      s.choice 'It is? Never mind, then.', false
      s.choice 'Go ahead.', true
    end

    if first_select
      final_select = prompt.select('I mean really permanent. It will delete all associated transaction data.') do |s|
        s.choice 'On second thought...', false
        s.choice 'Delete the account!', true
      end
    end

    if final_select
      prompt.say('Okay, then! Obliterating this account.')
      budget_id = bank_account.budget_id
      bank_account.destroy
      focus(bank_account: nil)
      sleep 1
      self.open_window('wallet')
    end

    self.open_window('wallet')
  end
end
