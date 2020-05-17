module StripeSynchronizationService
  ACTIVE_SUBSCRIPTION_STATUSES = ['active', 'trialing']
  # This will need to become a shared strand rather than a singleton when
  # individual user synchronization is re-enabled.
  SINGLETON_KEY = 'stripe-synchronization'
  # Number of seconds to wait after sync_all_users_later is invoked to kick off
  # synchronization. This in combination with the job being scheduled as a
  # singleton (which debounces any repeat schedulings before the job actually
  # runs) helps to cut down on extra jobs being kicked off if multiple webhook
  # events arrive all in short order.
  SYNC_DELAY = 15.seconds

  SubscriptionData = Struct.new(
    :id,
    :is_membership_subscription,
    :extracted_name,
    :start_date,
    :status,
    keyword_init: true
  )

  def self.sync_all_users_later
    send_later_enqueue_args(:sync_all_users_now, { singleton: SINGLETON_KEY, run_at: Time.now + SYNC_DELAY })
  end

  def self.sync_single_user_now(email, subscriptions)
    # TODO: redo how we sync subscriptions.
    # Stripe doesn't have a way to search customers by email case-insensitively
    # from their API and we have members who have entered their email in a
    # different case across the different times they've signed up for and
    # cancelled membership. For now we force synchronization of all users at
    # once to get around that (since that's only slightly more expensive than
    # synchronizing a single user but iterating through all customers to do
    # so). In the future, we'll want to work around this by being more
    # intelligent about how we synchronize customers and subscriptions;
    # specifically, we'll want to store a list of all customers for a user and
    # synchronize only the subscriptions belonging to those customers when
    # asked to sync a single user. Then we'll only need to sync all
    # subscriptions (and the customers associated with each user) when a
    # customer changes, which happens far less often than when a subscription
    # changes.

    # Filter out subscriptions that aren't memberships
    subscriptions = subscriptions.select { |subscription| subscription.is_membership_subscription }

    subscriptions = subscriptions.sort_by(&:start_date)
    active_subscriptions = subscriptions.select { |s| ACTIVE_SUBSCRIPTION_STATUSES.include?(s.status) }

    name = subscriptions.map(&:extracted_name).detect { |name| name.present? }

    TransactionRetry.run do
      User.transaction do
        user = User.find_for_authentication(email: email)
        user = User.new(email: email, name: name, password: SecureRandom.hex) unless user

        user.subscription_active = !active_subscriptions.empty?
        user.subscription_id = active_subscriptions.last&.id || subscriptions.last&.id

        start_date = active_subscriptions.last&.start_date || subscriptions.last&.start_date
        user.subscription_created = start_date ? Time.at(start_date) : nil

        user.save!
      end
    end
  end

  def self.sync_all_users_now
    Rails.logger.info('Synchronizing all subscriptions...')

    # When synchronizing all users, we load all subscriptions into memory. This
    # vastly increases the speed of synchronization, but it won't scale
    # forever. Luckily, the membership counts at which this will become a
    # problem are huge.
    subscriptions_by_email = {}
    subscription_count = 0

    Stripe::Subscription.list(status: 'all', expand: ['data.plan.product', 'data.customer'], limit: 25).auto_paging_each do |subscription|
      subscription_count += 1
      Rails.logger.info("#{subscription_count} subscriptions and counting...") if subscription_count % 100 == 0

      next if subscription.customer.respond_to?(:deleted) && subscription.customer.deleted
      next if !subscription.customer.email

      email = subscription.customer.email&.downcase
      subscriptions_by_email[email] ||= []
      subscriptions_by_email[email] << SubscriptionData.new(
        is_membership_subscription: is_membership_subscription?(subscription),
        extracted_name: extract_name(subscription),
        start_date: subscription.start_date,
        status: subscription.status
      )
    end

    Rails.logger.info("#{subscription_count} #{'subscription'.pluralize(subscription_count)}!")

    # Also sync users we know about but didn't find any subscriptions for. The
    # note above about things not scaling applies here because we load all
    # users' emails into memory at once, but it'll be a long time before that's
    # a problem.
    User.all.pluck(:email).each do |email|
      subscriptions_by_email[email.downcase] ||= []
    end

    Rails.logger.info("#{subscriptions_by_email.count} unique email addresses")

    subscriptions_by_email.each_with_index do |(email, subscriptions), index|
      sync_single_user_now(email, subscriptions)
      Rails.logger.info("#{index + 1} users updated and counting...") if (index + 1) % 100 == 0
    end

    Rails.logger.info('Done synchronizing all subscriptions.')
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

  def self.extract_name(subscription)
    return subscription.customer.name if subscription.customer.name.presence

    # Old subscriptions created by Paid Memberships Pro have a description of
    # the format "Full Name (email@address)". Newer subscriptions just use the
    # name as the description (the email is embedded in a separate field
    # anyway). Handle both formats gracefully.
    subscription.customer.description&.sub(/ *\([^)]+\)/, '')
  end
end
