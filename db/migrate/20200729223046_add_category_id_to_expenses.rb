class AddCategoryIdToExpenses < ActiveRecord::Migration[6.0]
  def change
    add_column(:expenses, :category_id, :integer)
  end
end
