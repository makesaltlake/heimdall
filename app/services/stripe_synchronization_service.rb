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
  SYNC_DELAY = 10.seconds

  def self.sync_all_users_later
    send_later_enqueue_args(:sync_all_users_now, { singleton: SINGLETON_KEY, run_at: Time.now + SYNC_DELAY })
  end

  def self.sync_single_user_now(email, subscriptions)
    Rails.logger.info("Synchronizing subscription for email #{email}...")

    # TODO: re-enable this and re-add ` = nil` after `subscriptions` in the
    # arguments to this method.
    # It's disabled because Stripe doesn't have a way to search customers by
    # email case-insensitively from their API and we have members who have
    # entered their email in a different case across the different times
    # they've signed up for and cancelled membership. For now we force
    # synchronization of all users at once to get around that (since that's
    # only slightly more expensive than synchronizing a single user but
    # iterating through all customers to do so). In the future, we'll want to
    # work around this by being more intelligent about how we synchronize
    # customers and subscriptions; specifically, we'll want to store a list of
    # all customers for a user and synchronize only the subscriptions belonging
    # to those customers when asked to sync a single user. Then we'll only need
    # to sync all subscriptions (and the customers associated with each user)
    # when a customer changes, which happens far less often than when a
    # subscription changes.
    # subscriptions = load_subscriptions_for_email(email) unless subscriptions

    # Filter out subscriptions that aren't memberships
    subscriptions = subscriptions.select { |subscription| is_membership_subscription?(subscription) }

    subscriptions = subscriptions.sort_by(&:start_date)
    active_subscriptions = subscriptions.select { |s| ACTIVE_SUBSCRIPTION_STATUSES.include?(s.status) }

    name = nil
    subscriptions.each do |subscription|
      name = extract_name(subscription).presence
      break if name
    end

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

    Rails.logger.info("Done synchronizing subscription for email #{email}.")
  end

  def self.sync_all_users_now
    Rails.logger.info('Synchronizing all subscriptions...')

    # When synchronizing all users, we load all subscriptions into memory. This
    # vastly increases the speed of synchronization, but it won't scale
    # forever. Luckily, the membership counts at which this will become a
    # problem are huge.
    subscriptions_by_email = {}
    subscription_count = 0

    Stripe::Subscription.list(status: 'all', expand: ['data.plan.product', 'data.customer'], limit: 100).auto_paging_each do |subscription|
      subscription_count += 1
      Rails.logger.info("#{subscription_count} subscriptions and counting...") if subscription_count % 100 == 0

      next if subscription.customer.respond_to?(:deleted) && subscription.customer.deleted

      email = subscription.customer.email.downcase
      subscriptions_by_email[email] ||= []
      subscriptions_by_email[email] << subscription
    end

    Rails.logger.info("#{subscription_count} #{'subscription'.pluralize(subscription_count)}!")

    # Also sync users we know about but didn't find any subscriptions for. The
    # note above about things not scaling applies here because we load all
    # users' emails into memory at once, but it'll be a long time before that's
    # a problem.
    User.all.pluck(:email).each do |email|
      subscriptions_by_email[email.downcase] ||= []
    end

    subscriptions_by_email.each do |email, subscriptions|
      sync_single_user_now(email, subscriptions)
    end

    Rails.logger.info('Done synchronizing all subscriptions.')
  end

  # See comment in sync_single_user_now for why this is commented out.
  #
  # def self.load_subscriptions_for_email(email)
  #   subscriptions = []
  #
  #   Stripe::Customer.list(email: email, limit: 100).auto_paging_each do |customer|
  #     Stripe::Subscription.list(customer: customer.id, status: 'all', expand: ['data.plan.product'], limit: 100).auto_paging_each do |subscription|
  #       subscriptions << subscription
  #     end
  #   end
  #
  #   subscriptions
  # end

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
