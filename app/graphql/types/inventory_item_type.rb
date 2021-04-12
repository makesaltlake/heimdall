class Types::InventoryItemType < Types::Base::BaseObject
  field :id, ID, null: false
  field :name, String, null: false
  field :part_number, String, null: true
end
