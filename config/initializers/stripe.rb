Stripe.api_key = ENV['STRIPE_SECRET_KEY']

# If you bump this, be sure to recreate the Stripe webhooks for each of your
# environments with the updated API version - otherwise webhook requests will
# continue to be sent using the old API version. (Or, write a thing to automate
# creation and updating of the webhook when deploying to an environment.)
Stripe.api_version = '2020-03-02'

# Not required, but let the folks at Stripe know who we are
Stripe.set_app_info('Heimdall', url: 'https://github.com/makesaltlake/heimdall')
