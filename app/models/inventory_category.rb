# == Schema Information
#
# Table name: inventory_categories
#
#  id                    :bigint           not null, primary key
#  description           :text
#  name                  :string           not null
#  toplevel_display_mode :string           default("show_when_orphaned"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  inventory_area_id     :bigint           not null
#
# Indexes
#
#  index_inventory_categories_on_inventory_area_id  (inventory_area_id)
#

class InventoryCategory < ApplicationRecord
  TOPLEVEL_DISPLAY_MODE_LABELS = {
    always_show: 'Always show this category at the top level',
    show_when_orphaned: 'Show this category at the top level only when it has no other parent categories',
    never_show: 'Never show this category at the top level'
  }.with_indifferent_access

  has_paper_trail

  has_many :child_inventory_category_categorizations, class_name: 'InventoryCategoryCategorization', foreign_key: :parent_inventory_category_id
  has_many :parent_inventory_category_categorizations, class_name: 'InventoryCategoryCategorization', foreign_key: :child_inventory_category_id
  has_many :child_inventory_categories, through: :child_inventory_category_categorizations
  has_many :parent_inventory_categories, through: :parent_inventory_category_categorizations

  has_many :inventory_item_categorizations
  has_many :inventory_items, through: :inventory_item_categorizations

  belongs_to :inventory_area

  enum toplevel_display_mode: { always_show: 'always_show', show_when_orphaned: 'show_when_orphaned', never_show: 'never_show' }

  validates :name, presence: true
  validates_associated :child_inventory_category_categorizations, :parent_inventory_category_categorizations, :inventory_item_categorizations
end
