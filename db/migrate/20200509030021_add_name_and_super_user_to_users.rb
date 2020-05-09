class AddNameAndSuperUserToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :name, :string
    add_column :users, :super_user, :boolean, default: false, null: false
  end
end
