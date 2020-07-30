class User < ActiveRecord::Base
  has_many :budgets

  has_many :bank_accounts, through: :budgets
  has_many :transactions, through: :bank_accounts

  has_many :categories, through: :budgets
  has_many :expenses, through: :categories
  
end
