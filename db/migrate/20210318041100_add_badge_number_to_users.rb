class AddBadgeNumberToUsers < ActiveRecord::Migration[6.0]
  def change
    # old column, was never used - badge_token took its place. time to use it!
    remove_column :users, :badge_number, :string
    add_column :users, :badge_number, :integer, limit: 4
  end
end
