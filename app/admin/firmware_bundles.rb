ActiveAdmin.register FirmwareBundle do
  menu parent: 'Developer Stuff'

  permit_params :device_type, :description, :firmware_blob

  config.sort_order = 'created_at_desc'

  filter :description
  filter :device_type, as: :select, collection: FirmwareBundle::DEVICE_TYPE_LABELS_TO_VALUES
  filter :active
  filter :created_at, label: 'Uploaded At'

  index do
    column(:uploaded, sortable: :created_at) { |firmware_bundle| auto_link(firmware_bundle) }
    column(:description) { |firmware_bundle| truncate(firmware_bundle.description, length: 100, separator: ' ') }
    column(:device_type, &:device_type_label)
    column(:active)
  end

  show do
    attributes_table do
      row(:description) { |firmware_bundle| format_multi_line_text(firmware_bundle.description) }
      row(:device_type, &:device_type_label)
      row(:active)
      row(:created_at)
    end
  end

  form do |f|
    f.inputs do
      f.input(:description)
      f.input(:device_type, as: :select, collection: FirmwareBundle::DEVICE_TYPE_LABELS_TO_VALUES) if f.object.new_record?

      f.input(:firmware_blob, as: :file, required: true) if f.object.new_record?
    end

    f.actions
  end

  action_item :activate, only: :show, if: -> { !resource.active? } do
    link_to 'Activate', activate_admin_firmware_bundle_path(resource), method: :post, data: { confirm: "Are you sure you want to activate this firmware bundle and roll it out to all #{resource.device_type_label} devices?" }
  end

  member_action :activate, method: :post do
    resource.activate!
    flash[:notice] = "This firmware bundle has been activated and is now being rolled out to all #{resource.device_type_label} devices. (To deactivate it, activate a different firmware bundle.)"
    redirect_to resource_path(resource), status: :see_other
  end

  controller do
    def action_methods
      result = super

      # Can't delete active firmware bundles
      result -= ['destroy'] if action_name == 'show' && resource.active?

      result
    end
  end
end
