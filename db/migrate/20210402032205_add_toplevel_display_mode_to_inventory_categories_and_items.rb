class AddToplevelDisplayModeToInventoryCategoriesAndItems < ActiveRecord::Migration[6.0]
  def change
    add_column :inventory_categories, :toplevel_display_mode, :string, null: false, default: 'show_when_orphaned'
    add_column :inventory_items, :toplevel_display_mode, :string, null: false, default: 'show_when_orphaned'
  end
end
