class CreateInventoryTables < ActiveRecord::Migration[6.0]
  def change
    create_table :inventory_areas do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    create_table :inventory_categories do |t|
      t.references :inventory_area, null: false

      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    create_table :inventory_category_categorizations do |t|
      t.references :parent_inventory_category, foreign_key: { to_table: :inventory_categories }, null: false, index: { name: 'index_inventory_category_categorizations_parent' }
      t.references :child_inventory_category, foreign_key: { to_table: :inventory_categories }, null: false, index: { name: 'index_inventory_category_categorizations_child' }

      t.timestamps
    end

    add_index :inventory_category_categorizations, [:parent_inventory_category_id, :child_inventory_category_id], unique: true, name: 'index_inventory_category_categorizations_uniquely'

    create_table :inventory_items do |t|
      t.references :inventory_area, null: false

      t.string :name, null: false
      t.string :part_number
      t.text :description

      t.integer :in_stock
      t.integer :target_amount

      t.text :procurement_url
      t.text :procurement_instructions

      t.timestamps
    end

    create_table :inventory_item_categorizations do |t|
      t.references :inventory_category, null: false
      t.references :inventory_item, null: false

      t.timestamps
    end

    add_index :inventory_item_categorizations, [:inventory_category_id, :inventory_item_id], unique: true, name: 'index_inventory_item_categorizations_uniquely'

    create_table :inventory_bins do |t|
      t.references :inventory_area
      t.text :notes

      t.references :inventory_item, optional: true

      t.timestamps
    end
  end
end
