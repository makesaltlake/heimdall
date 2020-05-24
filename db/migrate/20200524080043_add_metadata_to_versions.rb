class AddMetadataToVersions < ActiveRecord::Migration[6.0]
  def change
    add_column :versions, :metadata, :jsonb

    add_index :versions, :metadata, using: :gin
    add_index :versions, :object, using: :gin
    add_index :versions, :object_changes, using: :gin
  end
end
