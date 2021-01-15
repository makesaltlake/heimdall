class Webhooks::WaiverForeverController < ApplicationController
  skip_before_action :verify_authenticity_token

  def webhook
    # WaiverForever doesn't appear to provide any decent way to authenticate
    # the API requests they send, so we extract the ID only and fetch a fresh
    # copy of the data on our own in the background.
    waiver_id = params[:id]
    Rails.logger.info("Processing WaiverForever webhook for waiver #{waiver_id}")

    WaiverImportService.sync_single_waiver_later(waiver_id)

    render plain: 'OK'
  end
end
