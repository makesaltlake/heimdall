# == Schema Information
#
# Table name: inventory_areas
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class InventoryArea < ApplicationRecord
  has_paper_trail

  has_many :inventory_categories
  has_many :inventory_items
  has_many :inventory_bins

  validates :name, presence: true
end
