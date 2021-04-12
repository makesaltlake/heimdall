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
#  toplevel_display_mode    :string           default("show_when_orphaned"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  inventory_area_id        :bigint           not null
#
# Indexes
#
#  index_inventory_items_on_inventory_area_id  (inventory_area_id)
#

class InventoryItem < ApplicationRecord
  TOPLEVEL_DISPLAY_MODE_LABELS = {
    always_show: 'Always show this item at the top level',
    show_when_orphaned: 'Show this item at the top level only when it does not belong to any inventory categories',
    never_show: 'Never show this item at the top level'
  }.with_indifferent_access

  has_paper_trail

  has_many :inventory_item_categorizations
  has_many :inventory_categories, through: :inventory_item_categorizations

  belongs_to :inventory_area

  has_many :inventory_bins

  enum toplevel_display_mode: { always_show: 'always_show', show_when_orphaned: 'show_when_orphaned', never_show: 'never_show' }

  scope :toplevel_visible, -> { where("#{table_name}.toplevel_display_mode = 'always_show' OR (#{table_name}.toplevel_display_mode = 'show_when_orphaned' AND NOT EXISTS(SELECT 1 FROM inventory_item_categorizations WHERE inventory_item_categorizations.inventory_item_id = #{table_name}.id))") }

  validates :name, presence: true
  validates_associated :inventory_item_categorizations

  def display_name
    [part_number, name].compact.join(" ")
  end
end
