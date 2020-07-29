class Transaction < ActiveRecord::Base
  belongs_to :bank_account
  belongs_to :expense
  
  def display
    "#{self.amount} - #{self.expense.title}"
  end
end