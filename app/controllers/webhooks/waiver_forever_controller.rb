class Webhooks::WaiverForeverController < ApplicationController
  skip_before_action :verify_authenticity_token

  def webhook
    waiver_id = params[:id]
    Rails.logger.info("Processing WaiverForever webhook for waiver #{waiver_id}")

    WaiverImportService.sync_single_waiver_later(waiver_id)

    render plain: 'OK'
  end
end
