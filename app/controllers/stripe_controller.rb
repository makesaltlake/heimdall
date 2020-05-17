class StripeController < ApplicationController
  # The webhook signing secret to use to validate requests. Starts with
  # "whsec_".
  WEBHOOK_SECRET = ENV['STRIPE_WEBHOOK_SECRET']

  skip_before_action :verify_authenticity_token

  def webhook
    payload = request.body.read
    signature_header = request.headers['Stripe-Signature']

    event = Stripe::Webhook.construct_event(payload, signature_header, WEBHOOK_SECRET)

    case event.type
    when /^customer.subscription./
      StripeSynchronizationService.sync_all_users_later
    end

    render plain: 'OK'
  end
end
