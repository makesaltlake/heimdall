class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Add a shorthand alias for registering after_transaction_commit hooks
  def after_transaction_commit(&block)
    self.class.connection.after_transaction_commit(&block)
  end

  def self.inherited(subclass)
    super

    # Add a ransacker to every subclass that converts `id` to a string before
    # searching - that way the `id` field can be searched just like any other
    # field.
    #
    # TODO: figure out if there's a way we can just declare the ransacker on
    # `ApplicationRecord` itself - when we try, the block given to `ransacker`
    # gets run only once with `arel_table` empty and things are sad, so we'd
    # need to figure out a different way of doing it. Perhaps open an issue
    # against the ransack gem and see if there's a sanctioned way of doing
    # this.
    subclass.ransacker :id do
      Arel::Nodes::NamedFunction.new('CAST', [subclass.arel_table[:id].as('VARCHAR')])
    end
  end
end
