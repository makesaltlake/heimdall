class AddBadgeNumberToBadgeScans < ActiveRecord::Migration[6.0]
  def change
    add_column :badge_scans, :badge_number, :integer, limit: 4, index: true

    # also index users on their badge number
    add_index :users, :badge_number
  end
end
