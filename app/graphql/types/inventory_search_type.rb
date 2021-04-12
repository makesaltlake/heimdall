class Types::InventorySearchType < Types::Base::BaseObject
  field :inventory_categories, [Types::InventoryCategoryType], null: false
  def inventory_categories
    matching_categories = if object.inventory_category
      object.inventory_category.child_inventory_categories
    else
      InventoryCategory.toplevel_visible
    end

    matching_categories = matching_categories.where(inventory_area: object.inventory_area) if object.inventory_area

    matching_categories
  end

  field :inventory_items, [Types::InventoryItemType], null: false
  def inventory_items
    matching_items = if object.inventory_category
      object.inventory_category.inventory_items
    else
      InventoryItem.toplevel_visible
    end

    matching_items = matching_items.where(inventory_area: object.inventory_area) if object.inventory_area

    matching_items
  end

end
