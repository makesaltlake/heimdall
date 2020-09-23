# This module is basically a reimplementation of https://github.com/makesaltlake/synchrotron (which is a bot that posts
# stats whenever Make Salt Lake's membership counts change), except for the piece that automatically invited new
# members to MSL's Slack team because we now expect them to use MSL's Slackin instance to invite themselves.
module SynchrotronService
  extend ActionView::Helpers::NumberHelper

  STRAND = 'synchrotron-service-event-handling'
  SLACK_SYNCHROTRON_CHANNEL = ENV['SLACK_SYNCHROTRON_CHANNEL']

  Report = Struct.new(
    :total_count,
    :current_ongoing_count,
    :past_due_members,
    :pending_cancellation_members,
    :long_trial_members,
    :per_month_average,
    :per_month_average_before_fees,
    :per_month_baseline,
    keyword_init: true
  )

  SubscriptionSummary = Struct.new(:name, :email, :heimdall_id, :stripe_subscription_id, keyword_init: true)

  def self.create_report
    Rails.logger.info("Creating subscription report...")

    report = Report.new(
      total_count: 0,
      current_ongoing_count: 0,
      past_due_members: [],
      pending_cancellation_members: [],
      long_trial_members: [],
      per_month_average: 0,
      per_month_average_before_fees: 0,
      per_month_baseline: 0
    )

    Stripe::Subscription.list(expand: ['data.plan.product', 'data.customer'], limit: 25).auto_paging_each do |subscription|
      # Some plans don't have names. It looks like these are all deleted plans and it looks like all of those
      # correspond to subscriptions created by Paid Memberships Pro. They should be counted as memberships since they
      # do represent recurring revenue, but we should look into this further to see if there's a better way to decide
      # what to do with these.
      next unless StripeSynchronizationService.is_membership_subscription?(subscription)
      next unless subscription.customer&.email

      report.total_count += 1

      if ['active', 'trialing'].include?(subscription.status)
        if subscription.plan.interval != 'month'
          raise 'wtf'
        end

        if subscription.cancel_at_period_end
          report.pending_cancellation_members << summarize_subscription(subscription: subscription)
        elsif subscription.trial_end && Time.at(subscription.trial_end) > Time.now + 32.days
          report.long_trial_members << summarize_subscription(subscription: subscription)
        else
          report.current_ongoing_count += 1
          amount_after_transaction_fees = subscription.plan.amount * (1 - 0.029) - 0.3
          report.per_month_average += amount_after_transaction_fees / subscription.plan.interval_count
          report.per_month_average_before_fees += subscription.plan.amount / subscription.plan.interval_count

          if subscription.plan.interval_count == 1
            report.per_month_baseline += amount_after_transaction_fees
          end
        end
      else
        report.past_due_members << summarize_subscription(subscription: subscription)
      end
    end

    Rails.logger.info("Subscription report created.")

    report
  end

  def self.create_report_attachments(report)
    subscription_fields = [
      { title: 'Total subscriptions', value: report.total_count, short: true },
      { title: 'Current, ongoing subscriptions', value: report.current_ongoing_count, short: true },
      { title: 'Past due subscriptions', value: report.past_due_members.length, short: true },
      { title: 'Subscriptions pending cancellation', value: report.pending_cancellation_members.length, short: true },
      { title: 'Subscriptions with long trial periods', value: report.long_trial_members.length, short: true }
    ]

    projection_fields = [
      { title: 'Monthly average before Stripe fees', value: format_currency(report.per_month_average_before_fees), short: true },
      { title: 'Monthly average after Stripe fees', value: format_currency(report.per_month_average), short: true },
      { title: 'Monthly baseline after Stripe fees', value: format_currency(report.per_month_baseline), short: true }
    ]

    attachments = [
      {
        pretext: 'Subscription stats:',
        fields: subscription_fields
      },
      {
        pretext: 'Income projections for current, ongoing subscriptions:',
        fields: projection_fields
      }
    ]

    if report.past_due_members
      attachments << {
        pretext: 'Members with past due subscriptions:',
        text: report.past_due_members.map { |member| format_subscription_summary(member) }.join("\n")
      }
    end

    attachments
  end

  def self.report
    send_slack_message(attachments: create_report_attachments(create_report))
  end

  def self.summarize_subscription(customer: nil, subscription: nil, condensed: false)
    subscription = Stripe::Subscription.retrieve(subscription) if subscription.is_a?(String)

    customer = subscription.customer unless customer
    customer = Stripe::Customer.retrieve(customer) if customer.is_a?(String)

    SubscriptionSummary.new(
      name: StripeSynchronizationService.extract_name(customer),
      email: customer.email,
      heimdall_id: (User.find_for_authentication(email: customer.email.downcase)&.id unless condensed),
      stripe_subscription_id: (subscription.id unless condensed || !subscription)
    )
  end

  def self.format_subscription_summary(subscription_summary)
    if subscription_summary.heimdall_id
      heimdall_path = Rails.application.routes.url_helpers.admin_user_path(subscription_summary.heimdall_id)
      heimdall_url = HeimdallHost.full_url(heimdall_path)
      heimdall_link = "  <#{heimdall_url}|heimdall>" if heimdall_url # can be null if HEIMDALL_HOST isn't set, a.k.a. in local dev. we should probably change to infer localhost:5000 in that case.
    end

    if subscription_summary.stripe_subscription_id
      stripe_link = " <#{StripeUtils.dashboard_url(Stripe::Subscription, subscription_summary.stripe_subscription_id)}|stripe>"
    end

    [
      escape_slack_text(subscription_summary.name),
      escape_slack_text("(#{subscription_summary.email})"),
      heimdall_link,
      stripe_link
    ].compact.join(' ')
  end

  def self.short_subscription_summary(customer: nil, subscription: nil)
    format_subscription_summary(summarize_subscription(customer: customer, subscription: subscription, condensed: true))
  end

  def self.format_currency(amount)
    # number_to_currency comes from ActionView::Helpers::NumberHelper which is extended up top.
    # also, divide the amount by 100 since Stripe sends back amounts in cents and number_to_currency expects amounts
    # in dollars
    number_to_currency(amount / 100.0)
  end

  def self.month_and_day(epoch_time)
    Time.at(epoch_time).strftime('%B %-d')
  end

  def self.escape_slack_text(text)
    # TODO: this *should* be a thing slack-ruby-client is capable of doing but a quick glance didn't show how to do it.
    # Do a deeper dive and rewrite this to use whatever they've got to do it, or contribute this upstream if they really
    # don't have a way to do it.
    text.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def self.send_slack_message(**kwargs)
    unless SLACK_SYNCHROTRON_CHANNEL
      Rails.logger.info("Skipping sending a message to Slack because SLACK_SYNCHROTRON_CHANNEL has not been set")
      return
    end

    slack_client.chat_postMessage(channel: SLACK_SYNCHROTRON_CHANNEL, as_user: true, **kwargs)
  end

  def self.handle_stripe_event_later(event)
    send_later_enqueue_args(:handle_stripe_event_now, { strand: STRAND }, event)
  end

  def self.handle_stripe_event_now(event)
    Rails.logger.info("SynchrotronService: Handling webhook event...")

    case event.type
    when 'customer.subscription.created'
      send_slack_message(
        text: "New member: #{short_subscription_summary(subscription: event.data.object)}",
        attachments: create_report_attachments(create_report)
      )
    when 'customer.subscription.deleted'
      send_slack_message(
        text: "Cancellation: #{short_subscription_summary(subscription: event.data.object)}'s subscription has been cancelled.",
        attachments: create_report_attachments(create_report)
      )
    when 'customer.subscription.updated'
      cancel_at_period_end = event.data.object.cancel_at_period_end
      previous_attributes = event.data.previous_attributes || {}

      # Check to see if the subscription's cancel_at_period_end has changed
      if previous_attributes.keys.include?(:cancel_at_period_end) && cancel_at_period_end != previous_attributes['cancel_at_period_end']
        # It has. Check to see if it has one now; if so, this was a cancellation being scheduled (or being rescheduled
        # for another time)
        if cancel_at_period_end
          send_slack_message(
            text: "Scheduled cancellation: #{short_subscription_summary(customer: event.data.object.customer)}'s subscription will be cancelled on #{month_and_day(event.data.object.current_period_end)}",
            attachments: create_report_attachments(create_report)
          )
        else
          send_slack_message(
            text: "Reinstatement: #{short_subscription_summary(customer: event.data.object.customer)}'s subscription will no longer be cancelled.",
            attachments: create_report_attachments(create_report)
          )
        end
      end
    when 'invoice.payment_failed'
      send_slack_message(
        text: "Failed payment: #{short_subscription_summary(customer: event.data.object.customer)}'s payment failed :alert:",
        attachments: create_report_attachments(create_report)
      )
    when 'charge.dispute.created'
      Rails.logger.warn('A CHARGE HAS BEEN DISPUTED')

      send_slack_message(text: '<!channel> :beaker: A charge has been disputed :alert2:')
    else
      Rails.logger.info("SynchrotronService: Ignoring this event; it's not one we care about")
    end

    Rails.logger.info("SynchrotronService: Finished handling webhook event.")
  end

  def self.slack_client
    @slack_client ||= Slack::Web::Client.new
  end
end
