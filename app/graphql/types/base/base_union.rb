class Types::Base::BaseUnion < GraphQL::Schema::Union
  edge_type_class(Types::Base::BaseEdge)
  connection_type_class(Types::Base::BaseConnection)
end
