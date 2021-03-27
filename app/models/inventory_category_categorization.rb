# == Schema Information
#
# Table name: inventory_category_categorizations
#
#  id                           :bigint           not null, primary key
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  child_inventory_category_id  :bigint           not null
#  parent_inventory_category_id :bigint           not null
#
# Indexes
#
#  index_inventory_category_categorizations_child     (child_inventory_category_id)
#  index_inventory_category_categorizations_parent    (parent_inventory_category_id)
#  index_inventory_category_categorizations_uniquely  (parent_inventory_category_id,child_inventory_category_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (child_inventory_category_id => inventory_categories.id)
#  fk_rails_...  (parent_inventory_category_id => inventory_categories.id)
#

class InventoryCategoryCategorization < ApplicationRecord
  has_paper_trail

  belongs_to :parent_inventory_category, class_name: 'InventoryCategory'
  belongs_to :child_inventory_category, class_name: 'InventoryCategory'

  validate do
    unless parent_inventory_category.inventory_area_id === child_inventory_category.inventory_area_id
      errors[:child_inventory_category] << 'must be from the same inventory area'
    end
  end
end
