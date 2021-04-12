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

  # Helper method to fetch all objects of a given model type which have the
  # specified IDs and return them in exactly the order given, ignoring IDs
  # which don't exist. For example:
  #
  # User.by_ids_in_exact_order([1, 2, 3])
  #
  # is the same as (but executes only one query instead of three):
  #
  # [User.find_by(id: 1), User.find_by(id: 2), User.find_by(id: 3)].compact
  #
  # whereas:
  #
  # User.where(id: [1, 2, 3])
  #
  # might return them in a completely different order than the one given - say
  # 2, 3, 1.
  def self.by_ids_in_exact_order(ids)
    ids = ids&.map(&:to_i)
    by_ids = where(id: ids).to_a.index_by(&:id)
    ids.map { |id| by_ids[id] }.compact
  end
end
