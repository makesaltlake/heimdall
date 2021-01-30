class CreateFirmwareBundlesAndWirelessCredentialSets < ActiveRecord::Migration[6.0]
  def change
    create_table :firmware_bundles do |t|
      t.text :description
      t.string :device_type, null: false, index: true
      t.boolean :active, null: false, default: false, index: true

      t.timestamps
    end

    # Allow only one firmware bundle for a given device type to be active at a time
    add_index :firmware_bundles, :device_type, where: 'active', name: 'index_firmware_bundles_only_one_active_for_device_type'

    create_table :wireless_credential_sets do |t|
      t.string :ssid, null: false
      t.string :password, null: false

      t.timestamps
    end
  end
end
