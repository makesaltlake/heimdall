ActiveAdmin.register InventoryArea do
  menu parent: 'Inventory', priority: 1

  permit_params :name, :description

  filter :name
  filter :description

  index do
    column(:name) { |inventory_area| auto_link(inventory_area) }
    column(:description) { |inventory_area| truncate(inventory_area.description, length: 100, separator: ' ') }
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |inventory_area| format_multi_line_text(inventory_area.description) }
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:description)
    end
    f.actions
  end
end
