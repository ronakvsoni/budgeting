class CreateBankAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :bank_accounts do |t|
      t.integer :budget_id
      t.float :balance
      t.string :bank_name
    end
  end
end
