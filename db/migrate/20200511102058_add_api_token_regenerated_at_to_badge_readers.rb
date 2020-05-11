class AddApiTokenRegeneratedAtToBadgeReaders < ActiveRecord::Migration[6.0]
  def change
    add_column :badge_readers, :api_token_regenerated_at, :timestamp
  end
end
