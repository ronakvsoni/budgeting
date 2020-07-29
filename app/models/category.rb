class Category < ActiveRecord::Base
  belongs_to :budget
  has_many :expenses
  has_many :transactions, through: :expenses
  
end