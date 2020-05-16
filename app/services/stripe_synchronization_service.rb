module StripeSynchronizationService
  ACTIVE_SUBSCRIPTION_STATUSES = ['active', 'trialing']
  STRAND_NAME = 'stripe-synchronization'

  def self.sync_all_users_later
    send_later_enqueue_args(:sync_all_users_now, { strand: STRAND_NAME })
  end

  def self.sync_single_user_later(email, subscriptions = nil)
    send_later_enqueue_args(:sync_single_user_now, { strand: STRAND_NAME }, email, subscriptions)
  end

  def self.sync_single_user_now(email, subscriptions = nil)
    Rails.logger.info("Synchronizing subscription for email #{email}...")

    # fetch subscriptions for this user if they weren't specified
    subscriptions = load_subscriptions_for_email(email) unless subscriptions

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

      email = subscription.customer.email
      subscriptions_by_email[email] ||= []
      subscriptions_by_email[email] << subscription
    end

    Rails.logger.info("#{subscription_count} #{'subscription'.pluralize(subscription_count)}!")

    # Also sync users we know about but didn't find any subscriptions for. The
    # note above about things not scaling applies here because we load all
    # users' emails into memory at once, but it'll be a long time before that's
    # a problem.
    User.all.pluck(:email).each do |email|
      subscriptions_by_email[email] ||= []
    end

    subscriptions_by_email.each do |email, subscriptions|
      sync_single_user_now(email, subscriptions)
    end

    Rails.logger.info('Done synchronizing all subscriptions.')
  end

  def self.load_subscriptions_for_email(email)
    subscriptions = []

    Stripe::Customer.list(email: email, limit: 100).auto_paging_each do |customer|
      Stripe::Subscription.list(customer: customer.id, status: 'all', expand: ['data.plan.product'], limit: 100).auto_paging_each do |subscription|
        subscriptions << subscription
      end
    end

    subscriptions
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
