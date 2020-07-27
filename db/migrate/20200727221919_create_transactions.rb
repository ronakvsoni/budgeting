class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions do |t|
      t.integer :bank_account_id
      t.integer :expense_id
      t.float :amount
    end
  end
end
