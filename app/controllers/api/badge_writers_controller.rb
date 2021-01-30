class Api::BadgeWritersController < Api::ApiController
  include Api::Ext::HasFirmware
  include Api::Ext::HasWirelessCredentials

  authenticate_using BadgeWriter

  rescue_from BadgeWriter::DuplicateBadgeTokenError do
    render json: { status: :duplicate_badge_token }
  end

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
