class Expense < ActiveRecord::Base
  belongs_to :category
  has_many :transactions

end