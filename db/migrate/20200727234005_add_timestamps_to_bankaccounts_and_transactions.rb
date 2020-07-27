class AddTimestampsToBankaccountsAndTransactions < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :bank_accounts
    add_timestamps :transactions
  end
end
