class RenameExpenseNameColumnToTitle < ActiveRecord::Migration[6.0]
  def change
    rename_column(:expenses, :name, :title)
  end
end
