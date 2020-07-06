# Log errors generated in delayed jobs. Sentry's standard delayed_job integration works with inst-jobs as well.
require 'raven/integrations/delayed_job'

Raven.configure do |config|
  Rails.logger.warn('WARNING: No SENTRY_DSN specified') if HeimdallEnvironment.staging_or_production? && !ENV['SENTRY_DSN']

  config.dsn = ENV['SENTRY_DSN'] if ENV['SENTRY_DSN']

  config.current_environment = HeimdallEnvironment.environment

  # Increase timeouts to wait for Sentry to respond when sending events - which is fine because we're sending events in
  # a thread, so this won't block the user from doing anything while events are sent
  config.timeout = 5
  config.open_timeout = 5

  # Send events in a thread so as to avoid blocking whatever request triggers the event.
  # NOTE: We do *NOT* want to use a delayed job to send events in the background because delayed jobs will be backed
  # out if they're scheduled in a transaction that later rolls back, so do *NOT* change this to send in the background
  # by scheduling a job.
  config.async = lambda do |event|
    Thread.new do
      Rails.logger.debug("Heimdall: sending event #{event['event_id']} to Sentry in a thread...")
      Raven.send_event(event)
      Rails.logger.debug("Heimdall: event #{event['event_id']} sent to Sentry successfully.")
    end
  end
end
