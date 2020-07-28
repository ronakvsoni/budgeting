class Expense < ActiveRecord::Base
  belongs_to :bank_account
  # belongs_to :category
  
  has_many :transactions

end