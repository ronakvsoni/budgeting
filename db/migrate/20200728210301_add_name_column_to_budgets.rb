class AddNameColumnToBudgets < ActiveRecord::Migration[6.0]
  def change
    add_column(:budgets, :name, :string)
  end
end
