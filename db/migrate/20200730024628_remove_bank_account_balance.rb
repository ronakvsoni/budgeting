class RemoveBankAccountBalance < ActiveRecord::Migration[6.0]
  def change
    remove_column(:bank_accounts, :balance, :float)
  end
end
