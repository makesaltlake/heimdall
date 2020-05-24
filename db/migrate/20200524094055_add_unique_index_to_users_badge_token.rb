class AddUniqueIndexToUsersBadgeToken < ActiveRecord::Migration[6.0]
  def change
    add_index :users, :badge_token, unique: true
  end
end
