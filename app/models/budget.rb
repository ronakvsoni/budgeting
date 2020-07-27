class Budget < ActiveRecord::Base
  belongs_to :user
  has_many :bank_accounts
  has_many :transactions, through: :bank_accounts
  
end