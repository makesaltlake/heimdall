class Api::BadgeReadersController < Api::ApiController
  include Api::Ext::HasFirmware
  include Api::Ext::HasWirelessCredentials

  authenticate_using BadgeReader

  ACCESS_RECORD_TYPE_BADGE = 1
  ACCESS_RECORD_TYPE_KEYPAD = 2
  ACCESS_RECORD_TYPE_KEYPAD_ESCAPE = 3
  ACCESS_RECORD_TYPE_KEYPAD_TIMEOUT = 4

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

    allowed_badge_number_records = allowed_badge_numbers.map { |badge_number| [ACCESS_RECORD_TYPE_BADGE, 0, badge_number].pack("CCL<") }

    global_keypad_code = ENV['HEIMDALL_GLOBAL_KEYPAD_CODE']
    if global_keypad_code
      Integer(global_keypad_code) # Make sure it's a number
      allowed_badge_number_records << [ACCESS_RECORD_TYPE_KEYPAD, global_keypad_code.length, global_keypad_code.to_i].pack("CCL<")
    end

    binary_length = [allowed_badge_number_records.length].pack("L<")

    render plain: "#{binary_length}#{allowed_badge_number_records.join}"
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

  def record_binary_scan
    request_body = request.body.read
    type, length, badge_number, success = request_body.unpack("CCL<C")
    success = success == 1

    if type == ACCESS_RECORD_TYPE_BADGE
      TransactionRetry.transaction do
        resource.badge_scans.create!(
          badge_number: badge_number,
          user: User.find_by(badge_number: badge_number),
          authorized: success,
          scanned_at: Time.now, # TODO: have the badge reader report the time the scan happened and include it here
          submitted_at: Time.now
        )
      end
    end

    render plain: 'OK'
  end
end
