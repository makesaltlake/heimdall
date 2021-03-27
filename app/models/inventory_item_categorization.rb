# == Schema Information
#
# Table name: inventory_item_categorizations
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inventory_category_id :bigint           not null
#  inventory_item_id     :bigint           not null
#
# Indexes
#
#  index_inventory_item_categorizations_on_inventory_category_id  (inventory_category_id)
#  index_inventory_item_categorizations_on_inventory_item_id      (inventory_item_id)
#  index_inventory_item_categorizations_uniquely                  (inventory_category_id,inventory_item_id) UNIQUE
#

class InventoryItemCategorization < ApplicationRecord
  has_paper_trail

  belongs_to :inventory_category
  belongs_to :inventory_item

  validate do
    unless inventory_category.inventory_area_id === inventory_item.inventory_area_id
      errors[:inventory_item] << 'must be from the same inventory area'
    end
  end
end
