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
