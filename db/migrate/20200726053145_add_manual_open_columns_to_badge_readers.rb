class AddManualOpenColumnsToBadgeReaders < ActiveRecord::Migration[6.0]
  def change
    add_column :badge_readers, :last_manual_open_requested_at, :timestamp
    add_column :badge_readers, :last_manual_open_at, :timestamp
  end
end
