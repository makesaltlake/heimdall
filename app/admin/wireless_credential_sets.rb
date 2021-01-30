ActiveAdmin.register WirelessCredentialSet do
  menu parent: 'Developer Stuff'

  permit_params :ssid, :password

  config.sort_order = 'created_at_desc'

  filter :ssid

  index do
    column(:description) { |wireless_credential_set| auto_link(wireless_credential_set) }
    column('SSID', sortable: :ssid, &:ssid)
    column(:created_at)
  end

  show do
    attributes_table do
      row(:ssid, label: 'SSID')
      row(:password)
    end
  end

  form do |f|
    f.inputs do
      f.input(:ssid, label: 'SSID')
      f.input(:password, as: :string)
    end

    f.actions
  end
end
