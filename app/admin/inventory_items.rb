ActiveAdmin.register InventoryItem do
  menu parent: 'Inventory', priority: 3

  permit_params :name, :part_number, :description, :inventory_area_id, inventory_bin_ids: []

  filter :name
  filter :description
  filter :inventory_bins_id, as: :search_select_filter, display_name: 'display_name', fields: ['id'], label: 'Inventory Bin'

  index do
    column(:name) { |inventory_item| auto_link(inventory_item) }
    column(:part_number)
    column(:description) { |inventory_item| truncate(inventory_item.description, length: 100, separator: ' ') }
    column(:inventory_area)
  end

  show do
    attributes_table do
      row(:name)
      row(:part_number)
      row(:description) { |inventory_area| format_multi_line_text(inventory_area.description) }
      row(:inventory_area)
    end

    panel 'Location' do
      attributes_table_for resource do
        row(:inventory_bin, &:inventory_bins)
      end
    end
  end

  form do |f|
    f.inputs do
      f.input(:inventory_area) if resource.new_record?

      f.input(:name)
      f.input(:part_number)
      f.input(:description)

      f.input(:inventory_bin_ids, as: :selected_list, label: 'Inventory bin', display_name: 'display_name', fields: ['id'])
    end
    f.actions
  end

end
