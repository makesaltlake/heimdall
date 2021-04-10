ActiveAdmin.register InventoryCategory do
  menu parent: 'Inventory', priority: 2

  permit_params :name, :description, :inventory_area_id, parent_inventory_category_ids: [], child_inventory_category_ids: []

  filter :inventory_area
  filter :name
  filter :description
  filter :parent_inventory_categories

  index do
    column(:name) { |inventory_category| auto_link(inventory_category) }
    column(:description) { |inventory_category| truncate(inventory_category.description, length: 100, separator: ' ') }
    column(:inventory_area)
    column(:parent_categories, &:parent_inventory_categories)
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |inventory_category| format_multi_line_text(inventory_category.description) }
      row(:inventory_area)
      row(:toplevel_display_mode) { |inventory_category| InventoryCategory::TOPLEVEL_DISPLAY_MODE_LABELS[inventory_category.toplevel_display_mode] }
      row(:parent_categories, &:parent_inventory_categories)
      row(:child_categories, &:child_inventory_categories)
    end

    paginated_table_panel(
      resource.inventory_items,
      title: 'Inventory Items',
      param_name: :items_page
    ) do
      column(:name) { |inventory_item| auto_link(inventory_item) }
      column(:part_number_or_value, &:part_number)
      column(:description) { |inventory_item| truncate(inventory_item.description, length: 100, separator: ' ') }
    end
  end

  form do |f|
    f.inputs do
      f.input(:inventory_area) if resource.new_record?

      f.input(:name)
      f.input(:description)
      f.input(:toplevel_display_mode, as: :select, include_blank: false, collection: InventoryCategory::TOPLEVEL_DISPLAY_MODE_LABELS.invert)
    end

    f.inputs do
      f.input(:parent_inventory_category_ids, label: 'Parent categories', as: :selected_list, url: admin_inventory_categories_path)
      f.input(:child_inventory_category_ids, label: 'Child categories', as: :selected_list, url: admin_inventory_categories_path)
    end

    f.actions
  end
end
