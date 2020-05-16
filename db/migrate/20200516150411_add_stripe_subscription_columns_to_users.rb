class AddStripeSubscriptionColumnsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :subscription_active, :boolean
    add_column :users, :subscription_id, :string
    add_column :users, :subscription_created, :timestamp
  end
end
