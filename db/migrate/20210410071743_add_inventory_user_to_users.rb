class AddInventoryUserToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :inventory_user, :boolean, null: false, default: false
  end
end
