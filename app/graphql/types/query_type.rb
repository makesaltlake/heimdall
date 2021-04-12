class Types::QueryType < Types::Base::BaseObject
  # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
  # include GraphQL::Types::Relay::HasNodeField
  # include GraphQL::Types::Relay::HasNodesField

  # Add root-level fields here.
  # They will be entry points for queries on your schema.

  # TODO: remove me
  field :test_field, String, null: false, description: "An example field added by the generator"
  def test_field
    "Hello World!"
  end

  field :inventory_areas, [Types::InventoryAreaType], null: false
  def inventory_areas
    InventoryArea.all
  end

  field :inventory_area, Types::InventoryAreaType, null: true do
    argument :id, ID, required: false
  end
  def inventory_area(id: nil)
    InventoryArea.find_by(id: id)
  end

  field :default_inventory_area, Types::InventoryAreaType, null: true
  def default_inventory_area
    # Hardcoded for demo purposes. TODO: Remove once we have the ability to
    # switch between inventory areas in the frontend (or if we decide to allow
    # viewing things from all inventory areas, as I'm considering...)
    InventoryArea.find_by(name: 'Electronics') || InventoryArea.first
  end

  field :inventory_categories, [Types::InventoryCategoryType], null: false do
    argument :ids, [ID], required: true
  end
  def inventory_categories(ids:)
    result = InventoryCategory.by_ids_in_exact_order(ids)
    puts "ids: #{ids} and result: #{result}"
    result
  end

  field :inventory_category, [Types::InventoryCategoryType], null: true do
    argument :id, ID, required: false
  end
  def inventory_category(id: nil)
    InventoryCategory.find_by(id: id)
  end

  field :inventory_search, Types::InventorySearchType, null: false do
    argument :inventory_area_id, ID, required: false
    argument :inventory_category_id, ID, required: false
    argument :search_string, String, required: false
  end
  def inventory_search(inventory_area_id: nil, inventory_category_id: nil, search_string: nil)
    inventory_area = InventoryArea.find_by(id: inventory_area_id)
    inventory_category = InventoryCategory.find_by(id: inventory_category_id)

    OpenStruct.new(
      inventory_area: inventory_area,
      inventory_category: inventory_category,
      search_string: search_string
    )
  end
end
