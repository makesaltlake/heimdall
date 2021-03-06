module MembershipDeltaService
  def self.events
    # TODO: This could be more efficiently implemented using a from-scratch
    # query that utilizes Postgres window functions, but that's a task for
    # another day.
    TransactionRetry.transaction do
      events = []

      StripeSubscription.find_each do |subscription|
        events << OpenStruct.new(
          type: :join,
          delta: 1,
          date: subscription.started_at,
          name: subscription.customer_inferred_name,
          email: subscription.customer_email
        )
        events << OpenStruct.new(
          type: :cancel,
          delta: -1,
          date: subscription.ended_at,
          name: subscription.customer_inferred_name,
          email: subscription.customer_email
        ) if subscription.ended_at
      end

      events.sort_by!(&:date)

      total_members = 0

      events.each do |event|
        total_members += event.delta
        event.total_members = total_members
      end

      events
    end
  end

  # Returns events grouped by the specified granularity, which can be one of
  # :year, :month, :day, :hour, or :minute
  def self.group_by(granularity)
    events.group_by { |event| event.date.send(:"end_of_#{granularity}") }
  end

  # Returns a hash whose keys are dates of the given granularity and whose
  # values are the last event that occurred within that given unit of time.
  def self.last_by(granularity)
    group_by(granularity).transform_values(&:last)
  end

  def self.last_with_join_and_loss_counts(granularity)
    last_total_members = 0

    group_by(granularity).transform_values do |events|
      last_event = events.last
      last_event.join_count = events.select { |e| e.type == :join }.count
      last_event.cancel_count = events.select { |e| e.type == :cancel }.count
      last_event.delta_count = last_event.total_members - last_total_members
      last_event.join_percentage = ((last_event.join_count.to_f / last_event.total_members) * 100).round(1)
      last_event.cancel_percentage = ((last_event.cancel_count.to_f / (last_event.cancel_count + last_event.total_members)) * 100).round(1)
      last_event.delta_percentage = ((last_event.delta_count.to_f / last_event.total_members) * 100).round(1)

      last_total_members = last_event.total_members

      last_event
    end
  end
end
