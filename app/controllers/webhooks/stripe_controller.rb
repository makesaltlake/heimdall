class Webhooks::StripeController < ApplicationController
  # The webhook signing secret to use to validate requests. Starts with
  # "whsec_".
  WEBHOOK_SECRET = ENV['STRIPE_WEBHOOK_SECRET']

  skip_before_action :verify_authenticity_token

  def webhook
    payload = request.body.read
    signature_header = request.headers['Stripe-Signature']

    event = Stripe::Webhook.construct_event(payload, signature_header, WEBHOOK_SECRET)

    # Ditto for StripeSynchronizationService
    StripeSynchronizationService.handle_stripe_event_later(event: event)

    # Pass all events off to SynchrotronService. We could be more picky later on and filter out only ones it cares
    # about...
    SynchrotronService.handle_stripe_event_later(event: event)

    render plain: 'OK'
  end
end
