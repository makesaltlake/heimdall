module StripeSynchronizationService
  ACTIVE_SUBSCRIPTION_STATUSES = ['active', 'trialing']
  DEACTIVATED_SUBSCRIPTION_STATUSES = ['canceled', 'incomplete_expired']
  STRAND = 'stripe-synchronization'

  def self.handle_stripe_event_later(event)
    delay(strand: STRAND).handle_stripe_event_now(event)
  end

  def self.handle_stripe_event_now(event)
    Rails.logger.info("StripeSynchronizationService: Handling webhook event...")

    case event.type
    when 'customer.updated'
      update_customer_attributes_on_subscriptions(event)
    when 'customer.subscription.created', 'customer.subscription.updated', 'customer.subscription.deleted'
      # fetch the subscription afresh so that we have the latest state -
      # otherwise things might break if we receive two subscription updated
      # events out of order
      subscription = Stripe::Subscription.retrieve(
        id: event.data.object.id,
        expand: ['plan.product', 'customer']
      )

      create_or_update_subscription(subscription)
    end
  end

  def self.update_customer_attributes_on_subscriptions(event)
    # TODO - implement this (it's not hugely important since customer updates
    # are cosmetic things like name, email address, or card on file that
    # Heimdall doens't actually use). Once it's implemented, we'll want to
    # either run sync_all_subscriptions_later from a Rails console after
    # deploying or wait for the periodic job in
    # config/initializers/periodic_jobs.rb to trigger it to update
    # subscriptions with customer data that's out of date.
  end

  def self.create_or_update_subscription(subscription)
    TransactionRetry.transaction do
      customer = subscription.customer
      plan = subscription.plan

      # skip non-membership subscriptions for now. later we might want to do
      # something smarter with them, like include them but categorize them
      # differently in the UI.
      return false unless is_membership_subscription?(subscription)

      customer_email = customer.try(:email)&.downcase
      customer_inferred_name = extract_name(customer)

      stripe_subscription = StripeSubscription.find_by(subscription_id_in_stripe: subscription.id)
      unless stripe_subscription
        # need an email address in order to figure out who to attach this
        # subscription to - so if we don't have one, which would likely be
        # because the customer was deleted before we registered that we needed
        # to do anything about the subscription, then ignore the subscription.
        unless customer_email
          Rails.logger.warn("Warning: couldn't find or create a user for subscription #{subscription.id}. Probably the subscription's customer was deleted before we found out about it, so we don't know its email address.")
          return false
        end

        stripe_subscription = StripeSubscription.new(
          subscription_id_in_stripe: subscription.id,
          customer_id_in_stripe: customer.id,
        )

        stripe_subscription.user = locate_or_create_user_to_associate_with_subscription(customer_email, customer_inferred_name)
      end

      # email could be null if deleted, in which case we want to keep the
      # existing one around for posterity
      stripe_subscription.customer_email = customer_email if customer_email
      stripe_subscription.customer_name = customer.name
      stripe_subscription.customer_description = customer.description
      stripe_subscription.customer_inferred_name = customer_inferred_name

      stripe_subscription.active = ACTIVE_SUBSCRIPTION_STATUSES.include?(subscription.status)
      stripe_subscription.unpaid = !DEACTIVATED_SUBSCRIPTION_STATUSES.include?(subscription.status) && !stripe_subscription.active

      stripe_subscription.started_at = subscription.start_date && Time.at(subscription.start_date)
      stripe_subscription.ended_at = subscription.ended_at && Time.at(subscription.ended_at)
      stripe_subscription.canceled_at = subscription.canceled_at && Time.at(subscription.canceled_at)
      stripe_subscription.cancel_at = subscription.cancel_at && Time.at(subscription.cancel_at)

      stripe_subscription.plan_name = subscription.plan.product.try(:name)
      stripe_subscription.interval = subscription.plan.interval_count
      stripe_subscription.interval_type = subscription.plan.interval
      stripe_subscription.interval_amount = subscription.plan.amount

      changed = stripe_subscription.changed?
      stripe_subscription.save!

      changed
    end
  end

  def self.locate_or_create_user_to_associate_with_subscription(email, inferred_name)
    # first, try finding a user with exactly the email specified
    user = User.find_for_authentication(email: email)
    return user if user

    # no user matched exactly, so search for a subscription whose email
    # address matches and, if one exists, pick the user associated with the
    # most recently created such subscription. that'll help us in scenarios
    # where a user has multiple email addresses and uses different ones to
    # sign up for membership vs. to log into heimdall; in such a case, the
    # user created for the member's membership email address can be merged
    # with their heimdall user, associating the subscriptions to that user,
    # and then on future signups we'll see those subscriptions and associate
    # their new subscription with the same user.
    previous_subscription = StripeSubscription.where(customer_email: email).where.not(user: nil, started_at: nil).order(started_at: :desc).take
    if previous_subscription
      Rails.logger.info("Inferring user account for new signup for email #{email} to be user ##{previous_subscription.user.id} based on past subscriptions")
      return previous_subscription.user
    end

    # no subscriptions matched. assume this is a signup for someone we've
    # never seen before and create and return a new user for them.
    User.create!(email: email, name: inferred_name, password: Devise.friendly_token)
  end

  def self.sync_all_subscriptions_later
    delay(strand: STRAND).sync_all_subscriptions_now
  end

  def self.sync_all_subscriptions_now
    Rails.logger.info("Synchronizing all Stripe subscriptions...")

    subscription_count = 0
    changed_subscription_count = 0

    Stripe::Subscription.list(status: 'all', expand: ['data.plan.product', 'data.customer'], limit: 25).auto_paging_each do |subscription|
      subscription_count += 1
      Rails.logger.info("#{subscription_count} subscriptions and counting...") if subscription_count % 100 == 0

      changed_subscription_count += 1 if create_or_update_subscription(subscription)
    end

    Rails.logger.info("#{subscription_count} #{'subscription'.pluralize(subscription_count)}!")

    if changed_subscription_count > 0
      Rails.logger.warn("Warning: #{changed_subscription_count} subscription(s) changed as part of this update. That means that either you were performing a first-time sync with Stripe or the webhook-based updater missed something earlier, in which case you'll want to track down why. (Or, a subscription was created midway through this loop, in which case no problemo.)")
    else
      Rails.logger.info("No subscriptions were updated, which is good: that means the webhook-based updater is doing its job and updating subscriptions as they're changed.")
    end
  end

  def self.is_membership_subscription?(subscription)
    # Plans without names appear to be old, deleted plans created by Paid
    # Memberships Pro back when that was what we used to manage memberships.
    # They almost certainly represent cancelled subscriptions, but no reason
    # not to count them as memberships since they'll be filtered out on that
    # basis later.
    product = subscription.plan.product
    !product.respond_to?(:name) || !product.name || product.name.downcase.include?('membership')
  end

  def self.extract_name(customer)
    return customer.name if customer.try(:name).presence

    # Old subscriptions created by Paid Memberships Pro have a description of
    # the format "Full Name (email@address)". Newer subscriptions just use the
    # name as the description (the email is embedded in a separate field
    # anyway). Handle both formats gracefully.
    customer.try(:description)&.sub(/ *\([^)]+\)/, '')
  end
end
