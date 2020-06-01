class AddBadgeTokenAndBadgeIdAndAuthorizedToBadgeScans < ActiveRecord::Migration[6.0]
  def change
    change_table :badge_scans do |t|
      t.string :badge_token
      t.string :badge_id, index: true
      t.boolean :authorized, index: true, default: true
    end
  end
end
