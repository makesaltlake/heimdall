class AddRestrictedAccessToBadgeReaders < ActiveRecord::Migration[6.0]
  def change
    add_column :badge_readers, :restricted_access, :boolean, default: false, null: false
  end
end
