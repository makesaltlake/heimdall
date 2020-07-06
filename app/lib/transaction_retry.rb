module TransactionRetry
  MAX_ATTEMPTS = 5

  def self.run
    attempts_remaining = MAX_ATTEMPTS
    begin
      yield
    rescue ActiveRecord::TransactionRollbackError
      attempts_remaining -= 1
      if attempts_remaining > 0
        Rails.logger.info('Transaction conflict detected, retrying')
        retry
      else
        Rails.logger.warn('Transaction conflict detected, aborting transaction')
        Raven.capture_message("Transaction aborted after reaching #{MAX_ATTEMPTS} attempts. Consider raising the limit in app/lib/transaction_retry.rb. Or, if the failure was because of a deadlock, consider adding logic to delay between each retry.")
        raise
      end
    end
  end
end
