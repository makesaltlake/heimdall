class Api::BadgeReadersController < Api::ApiController
  include Api::Ext::HasFirmware
  include Api::Ext::HasWirelessCredentials

  authenticate_using BadgeReader

  def access_list
    allowed_badge_tokens = resource.badge_access_grant_users.where.not(badge_token: nil).pluck(:badge_token)

    render json: {
      badge_tokens: allowed_badge_tokens
    }
  end

  def binary_access_list
    allowed_badge_numbers = resource.badge_access_grant_users.where.not(badge_number: nil).pluck(:badge_number)

    # Response is a list of 4-byte big endian unsigned integers, the first of which is the number of badges that are
    # allowed and the remainder of which are the allowed badge numbers themselves. That number of badges field at the
    # beginning is so that we can later add additional data onto the response that badge readers with old firmware will
    # know to ignore.
    binary_length = [allowed_badge_numbers.length].pack("L>")
    binary_badge_numbers = allowed_badge_numbers.map { |badge_number| [badge_number].pack("L>") }.join

    render plain: "#{binary_length}#{binary_badge_numbers}"
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
