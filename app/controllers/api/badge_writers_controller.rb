class Api::BadgeWritersController < Api::ApiController
  authenticate_using BadgeWriter

  def program
    user = resource.program_badge!(params[:badge_token])

    if user
      render json: {
        status: :ok,
        user: {
          name: user.name
        }
      }
    else
      # the badge writer wasn't set to program a badge right now
      render json: { status: :not_programming }
    end
  end
end
