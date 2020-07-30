module BudgetInterface
  def select_budget_menu(p = {})
    focus(budget: nil) #clear the current focus for budget

    budgets = self.user.budgets

    if budgets.empty?
      go = prompt.select('Looks like you have no budgets! Ready to create one?') do |s|
        s.choice 'Yeah, let\'s do it!', true
        s.choice 'Not right now! Let\'s go back.', false
      end

      go ? self.open_window('create budget') : self.open_window('user_dashboard')
    else
      menu_select = prompt.select('Okay, I found these budgets:') do |s|
        self.user.budgets.each { |budget| s.choice budget.name, budget.id }
        s.choice 'I\'d like to create a new budget, please!', 'create_budget'
        s.choice 'On second thought, dashboard me again.', 'user_dashboard'
      end

      !!(menu_select.class == Integer) ? self.open_window('view_budget', budget_id: menu_select) : self.open_window(menu_select)
    end
  end

  def create_budget(p = {})
    name = prompt.ask('First, name your budget:', modify: :collapse)
    prompt.say('Good name! Loading it up...')
    budget = Budget.create(name: name, user_id: self.user.id)
    sleep 2
    self.open_window('view_budget', budget_id: budget.id)
  end

  def view_budget(p = {})
    self.system_clear

    budget = Budget.find(p[:budget_id])
    focus(budget: budget)

    prompt.say("Name: #{budget.name}     Created: #{budget.created_at}     Last Updated: #{budget.updated_at}")

    menu_select = prompt.select('Let me know what you\'d like to see:') do |s|
      s.choice 'Wallet', 'wallet'
      s.choice 'Options, please!', 'edit_budget'
      s.choice 'Show me all my budgets again?', 'select_budget_menu'
    end

    self.open_window(menu_select)
  end

  def edit_budget(p = {})
    self.system_clear

    budget = session_focus(:budget)

    prompt.say("Name: #{budget.name}     Created: #{budget.created_at}     Last Updated: #{budget.updated_at}")

    menu_select = prompt.select('What would you like to do?') do |s|
      s.choice 'Let\'s rename this budget.', 'rename_budget'
      s.choice 'I want to delete this budget.', 'delete_budget'
      s.choice 'Wrong turn! Take me back.', false
    end

    menu_select ? self.open_window(menu_select) : self.open_window('view_budget', budget_id: budget.id)
  end

  def rename_budget(p = {})
    budget = session_focus(:budget)

    name = prompt.ask('I didn\'t like that name either. What do you want me to call it now?')

    budget.name = name
    budget.save
    prompt.say("Nice! Renaming this budget to #{name}...")

    sleep 2

    prompt.say('You\'re all set!')

    sleep 1

    self.open_window('edit_budget')
  end

  def delete_budget(p = {})
    budget = session_focus(:budget)

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

      self.open_window('edit_budget')
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
      focus(budget: nil)
  
      sleep 1

      prompt.say('Done! Now go look at your other budgets while I sweep up this dust.')

      sleep 2

      self.system_clear
      self.open_window('select_budget_menu')
    end
  end 
end
