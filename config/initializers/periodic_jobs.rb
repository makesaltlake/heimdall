Delayed::Periodic.cron 'Synchronize all Stripe subscriptions', '30 5 * * 0' do
  StripeSynchronizationService.sync_all_subscriptions_later
end

Delayed::Periodic.cron 'Synchronize all waivers', '30 4 * * 0' do
  WaiverImportService.sync_all_waivers_later
end
