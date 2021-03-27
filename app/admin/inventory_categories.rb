ActiveAdmin.register InventoryCategory do
  menu parent: 'Inventory', priority: 2

  permit_params :name, :description, :inventory_area_id, parent_inventory_category_ids: [], child_inventory_category_ids: []

  filter :inventory_area
  filter :name
  filter :description

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
      row(:parent_categories, &:parent_inventory_categories)
      row(:child_categories, &:child_inventory_categories)
    end
  end

  form do |f|
    f.inputs do
      f.input(:inventory_area) if resource.new_record?

      f.input(:name)
      f.input(:description)
    end

    f.inputs do
      f.input(:parent_inventory_category_ids, label: 'Parent categories', as: :selected_list, url: admin_inventory_categories_path)
      f.input(:child_inventory_category_ids, label: 'Child categories', as: :selected_list, url: admin_inventory_categories_path)
    end

    f.actions
  end
end
