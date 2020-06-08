class Api::BadgeReadersController < Api::ApiController
  authenticate_using BadgeReader

  def access_list
    allowed_badge_tokens = resource.badge_access_grant_users.where.not(badge_token: nil).pluck(:badge_token)

    render json: {
      badge_tokens: allowed_badge_tokens
    }
  end

  def record_scans
    TransactionRetry.run do
      BadgeReader.transaction do
        params[:scans].each do |scan|
          resource.badge_scans.create!(
            badge_id: scan.fetch(:badge_id),
            badge_token: scan.fetch(:badge_token),
            user: User.find_by(badge_token: scan.fetch(:badge_token)),
            authorized: scan.fetch(:authorized),
            scanned_at: Time.at(scan.fetch(:scanned_at)),
            submitted_at: Time.now
          )
        end
      end
    end

    render json: { status: :ok }
  end
end
