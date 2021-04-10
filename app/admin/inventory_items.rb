ActiveAdmin.register InventoryItem do
  menu parent: 'Inventory', priority: 3

  permit_params :name, :part_number, :description, :inventory_area_id, :target_amount, :in_stock, inventory_bin_ids: [], inventory_category_ids: []

  filter :inventory_area
  filter :name
  filter :description
  filter :inventory_categories
  filter :inventory_bins_id, as: :search_select_filter, display_name: 'display_name', fields: ['id'], label: 'Inventory Bin'

  index do
    column(:inventory_item) { |inventory_item| auto_link(inventory_item) }
    column(:name)
    column(:part_number_or_value, &:part_number)
    column(:description) { |inventory_item| truncate(inventory_item.description, length: 100, separator: ' ') }
    column(:inventory_area)
    column(:inventory_categories)
    column(:inventory_bin) { |inventory_item| inventory_item.inventory_bins.map { |bin| auto_link(bin, "Bin ##{bin.id}") } }
  end

  show do
    attributes_table do
      row(:name)
      row(:part_number_or_value, &:part_number)
      row(:description) { |inventory_item| format_multi_line_text(inventory_item.description) }
      row(:inventory_area)
      row(:inventory_categories)
      row(:toplevel_display_mode) { |inventory_item| InventoryItem::TOPLEVEL_DISPLAY_MODE_LABELS[inventory_item.toplevel_display_mode] }
    end

    panel 'Location' do
      attributes_table_for resource do
        row(:inventory_bin, &:inventory_bins)
      end
    end

    panel 'Stock' do
      attributes_table_for resource do
        row(:target_amount)
        row(:in_stock)
      end
    end
  end

  form do |f|
    f.inputs do
      f.input(:inventory_area) if resource.new_record?

      f.input(:name)
      f.input(:part_number, label: 'Part number or value')
      f.input(:description)
      f.input(:toplevel_display_mode, as: :select, include_blank: false, collection: InventoryItem::TOPLEVEL_DISPLAY_MODE_LABELS.invert)
    end

    f.inputs do
      f.input(:inventory_bin_ids, as: :selected_list, label: 'Inventory bin', display_name: 'display_name', fields: ['id'])
    end

    f.inputs do
      f.input(:inventory_category_ids, label: 'Categories', as: :selected_list, url: admin_inventory_categories_path)
    end

    f.inputs do
      f.input(:target_amount)
      f.input(:in_stock)
    end

    f.actions
  end

  action_item :duplicate, only: :show do
    link_to("Duplicate", duplicate_admin_inventory_item_path(id: resource.id))
  end

  member_action :duplicate, method: :get do
    @resource = resource.dup
    @resource.inventory_categories = resource.inventory_categories
    render :new, layout: false
  end
end
