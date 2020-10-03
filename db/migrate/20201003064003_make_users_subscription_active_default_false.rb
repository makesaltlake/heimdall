class MakeUsersSubscriptionActiveDefaultFalse < ActiveRecord::Migration[6.0]
  def change
    change_column_default :users, :subscription_active, false
    change_column_null :users, :subscription_active, false
  end
end
