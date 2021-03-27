module TransactionRetry
  MAX_ATTEMPTS = 5

  # Runs the given block inside a transaction. If the transaction rolls back
  # because of a database conflict, the block will be automatically re-run, up
  # to a maximum of MAX_ATTEMPTS times. If the block throws any other
  # exception, the transaction will be immediately aborted and no further
  # retries will be made.
  def self.transaction
    run do
      ActiveRecord::Base.transaction(requires_new: true) do
        yield
      end
    end
  end

  # Run the given block, which is expected to start and commit a single
  # database transaction. If the transaction rolls back because of a database
  # conflict, the block will be automatically re-run, up to a maximum of
  # MAX_ATTEMPTS times. If the block throws any other exception, the
  # transaction will be immediately aborted and no further retries will be
  # made.
  #
  # The expected usage is:
  #
  # TransactionRetry.run do
  #   ActiveRecord::Base.transaction do
  #     # ...code here...
  #   end
  # end
  #
  # (Alternatively, you can use TransactionRetry.transaction to combine the
  # two steps. You should probably use that unless you have a good reason to
  # need fine-grained control over how the transaction gets kicked off.)
  def self.run
    # If we're currently running in a transaction, then that means the user is
    # using nested transactions and they're about to start a nested one from
    # within the block given to us - so no use catching exceptions and
    # retrying here since the entire transaction will have been aborted.
    if ActiveRecord::Base.connection.transaction_open?
      return yield
    end

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
