class Types::Base::BaseObject < GraphQL::Schema::Object
  edge_type_class(Types::Base::BaseEdge)
  connection_type_class(Types::Base::BaseConnection)
  field_class Types::Base::BaseField
end
