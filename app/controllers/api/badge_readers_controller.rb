class Api::BadgeReadersController < Api::ApiController
  authenticate_using BadgeReader

  def access_list
    # TODO: actually filter the list down to users who can access this badge
    # reader. For the purposes of testing we're just returning every badge in
    # the system.
    render json: {
      badge_tokens: User.where.not(badge_token: nil).pluck(:badge_token)
    }
  end

  def record_scans
  end
end
