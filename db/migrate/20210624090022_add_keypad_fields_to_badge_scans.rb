class AddKeypadFieldsToBadgeScans < ActiveRecord::Migration[6.0]
  def change
    add_column :badge_scans, :keypad_code, :string
    add_column :badge_scans, :badge_scan_type, :string
  end
end
