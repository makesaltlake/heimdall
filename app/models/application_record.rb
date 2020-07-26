class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def after_transaction_commit(&block)
    self.class.connection.after_transaction_commit(&block)
  end
end
