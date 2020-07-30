class BankAccount < ActiveRecord::Base
  belongs_to :budget
  has_many :transactions

  def balance
    0.00 + self.transactions.map(&:amount).sum
  end

  def display_balance
    sprintf('%.2f', self.balance)
  end
end