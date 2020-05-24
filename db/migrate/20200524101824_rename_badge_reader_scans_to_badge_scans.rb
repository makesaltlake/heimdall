class RenameBadgeReaderScansToBadgeScans < ActiveRecord::Migration[6.0]
  def change
    rename_table :badge_reader_scans, :badge_scans

    versions_class = Class.new(ActiveRecord::Base) do
      self.table_name = 'versions'
    end

    reversible do |dir|
      dir.up do
        versions_class.where(item_type: 'BadgeReaderScan').update_all(item_type: 'BadgeScan')
      end
      dir.down do
        versions_class.where(item_type: 'BadgeScan').update_all(item_type: 'BadgeReaderScan')
      end
    end
  end
end
