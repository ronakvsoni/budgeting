class AddLastOpenedBudgetColumnToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column(:users, :last_opened_budget, :integer)
  end
end
