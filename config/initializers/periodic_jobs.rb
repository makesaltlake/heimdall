Delayed::Periodic.cron 'Synchronize all Stripe subscriptions', '30 5 * * *' do
  StripeSynchronizationService.sync_all_subscriptions_later
end
