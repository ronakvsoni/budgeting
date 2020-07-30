class Transaction < ActiveRecord::Base
  belongs_to :bank_account
  belongs_to :expense
  
  def display
    expense_title = (!!self.expense ? self.expense.title : 'Uncategorized')
    "#{self.amount} - #{expense_title}"
  end
end