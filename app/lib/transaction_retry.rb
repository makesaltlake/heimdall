module TransactionRetry
  def self.run
    attempts_remaining = 5
    begin
      yield
    rescue ActiveRecord::SerializationFailure
      attempts_remaining -= 1
      if attempts_remaining > 0
        Rails.logger.info('Transaction conflict detected, retrying')
        retry
      else
        Rails.logger.warn('Transaction conflict detected, aborting transaction')
        raise
      end
    end
  end
end
