class Ability
  include CanCan::Ability

  def initialize(user)
    # Super users can do everything
    can :manage, :all if user.super_user?

    # Inventory users can do everything with inventory models
    if user.inventory_user?
      can :manage, [InventoryArea, InventoryCategory, InventoryItem, InventoryBin]
      can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
    end
  end
end
