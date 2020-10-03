Delayed::Periodic.cron 'Synchronize all Stripe subscriptions', '0 4 * * *' do
  StripeSynchronizationService.sync_all_subscriptions_later
end
