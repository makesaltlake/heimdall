# == Schema Information
#
# Table name: inventory_items
#
#  id                       :bigint           not null, primary key
#  description              :text
#  in_stock                 :integer
#  name                     :string           not null
#  part_number              :string
#  procurement_instructions :text
#  procurement_url          :text
#  target_amount            :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  inventory_area_id        :bigint           not null
#
# Indexes
#
#  index_inventory_items_on_inventory_area_id  (inventory_area_id)
#

class InventoryItem < ApplicationRecord
  has_paper_trail

  has_many :inventory_item_categorizations
  has_many :inventory_categories, through: :inventory_item_categorizations

  belongs_to :inventory_area

  has_many :inventory_bins

  validates :name, presence: true
  validates_associated :inventory_item_categorizations
end
