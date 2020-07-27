class Transaction < ActiveRecord::Base
  belongs_to :bank_account
  
end