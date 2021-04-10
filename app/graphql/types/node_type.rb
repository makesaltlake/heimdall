module Types::NodeType
  include Types::Base::BaseInterface
  # Add the `id` field
  include GraphQL::Types::Relay::NodeBehaviors
end
