class Ability
  include CanCan::Ability

  def initialize(user)
    # Super users can do everything
    can :manage, :all if user.super_user?
  end
end
