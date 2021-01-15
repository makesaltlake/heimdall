class WaiverImportService
  WAIVER_FOREVER_BASE_URL = 'https://api.waiverforever.com/openapi/v1'
  WAIVER_FOREVER_API_KEY = ENV['WAIVER_FOREVER_API_KEY']
  STRAND = 'waiver-import-service-strand'

  def self.create_or_update_waiver(waiver_json)
    waiver = Waiver.find_or_initialize_by(waiver_forever_id: waiver_json['id'])

    fields = waiver_json['data']
    # scan through the waiver's custom fields and use the first one whose type is 'email_field' as the email
    email = fields.select { |field| field['type'] == 'email_field' }.first&.[]('value')
    # ditto for the waiver's name
    name = fields.select { |field| field['type'] == 'name_field' }.first&.[]('value')
    signed_at = waiver_json['signed_at']

    waiver.email = email
    waiver.name = name
    waiver.fields = fields
    waiver.signed_at = signed_at && Time.at(signed_at)

    waiver.save!
  end

  def self.sync_all_waivers_later
    delay(strand: STRAND).sync_all_waivers_now
  end

  def self.sync_all_waivers_now
    current_page = 1

    Rails.logger.info("Synchronizing all WaiverForever waivers...")

    loop do
      Rails.logger.info("Page #{current_page}...")

      response = WaiverImportService.api_client.post('waiver/search', { per_page: 25, page: current_page })
      raise "couldn't pull down waivers on page #{current_page}: #{response}" unless response.body&.[]('result')

      current_page += 1
      raise "too many pages; possible change to waiverforever's API?" if current_page > 30000

      waivers = response.body['data']['waivers']
      break if waivers.blank? # we get back an empty array once we've gone through all the pages

      waivers.each do |waiver|
        create_or_update_waiver(waiver)
      end
    end

    Rails.logger.info("Done synchronizing waivers.")
  end

  def self.sync_single_waiver_later(waiver_id)
    delay(strand: STRAND).sync_single_waiver_now(waiver_id)
  end

  def self.sync_single_waiver_now(waiver_id)
    Rails.logger.info("Synchronizing a single waiver: #{waiver_id}...")

    begin
      waiver_data = WaiverImportService.api_client.get("waiver/#{waiver_id}").body['data']
    rescue Faraday::ResourceNotFound
      Rails.logger.warn("Warning: doesn't look like there's a waiver with ID #{waiver_id}, skipping synchronization")
      return
    end

    create_or_update_waiver(waiver_data)

    Rails.logger.info("Done synchronizing a single waiver: #{waiver_id}.")
  end

  def self.api_client
    Faraday.new(url: WAIVER_FOREVER_BASE_URL) do |connection|
      connection.request :json
      connection.response :json, content_type: /\bjson\b/
      connection.use Faraday::Response::RaiseError
      connection.use Faraday::Adapter::NetHttp
      connection.headers['X-API-Key'] = WAIVER_FOREVER_API_KEY
    end
  end
end
