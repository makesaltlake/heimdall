module StripeUtils
  # Returns either "live" or "test", depending on which mode
  # ENV['STRIPE_API_KEY'] is for, or nil if Stripe is not set up.
  def self.mode
    if Stripe.api_key
      # first character can be either s or r depending on whether it's a
      # full key or a restricted key
      Stripe.api_key.match(/^[rs]k_live/) ? 'live' : 'test'
    end
  end

  # Returns '/test' if we're in test mode or '' if we're in live mode. This is
  # suitable for adding to generated Stripe dashboard URLs after the domain
  # name.
  def self.dashboard_url_prefix
    mode == 'test' ? '/test' : ''
  end

  # Takes a Stripe resource type and ID and generates a link to the Stripe
  # dashboard where that resource can be managed. For example,
  # StripeUtils.dashboard_url(Stripe::Subscription, 'foobar') would generate a
  # url like 'https://dashboard.stripe.com/subscriptions/foobar'.
  def self.dashboard_url(resource_type, resource_id)
    return unless resource_id

    path = if resource_type == Stripe::Subscription
      "/subscriptions/#{resource_id}"
    else
      raise "not a supported resource type: #{resource_type}. please update StripeUtils.dashboard_url to handle this type."
    end

    "https://dashboard.stripe.com#{dashboard_url_prefix}#{path}"
  end
end
