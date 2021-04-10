# == Schema Information
#
# Table name: counters
#
#  id         :bigint           not null, primary key
#  name       :string
#  value      :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_counters_on_name  (name) UNIQUE
#

class Counter < ApplicationRecord
  # A method that can be used to generate sequential values. Like database
  # sequences, but unlike sequences as implemented by Postgres, this method
  # returns sequential numbers even after being invoked by a transaction that
  # was rolled back.
  #
  # To illustrate, imagine that you created a model like:
  #
  # class Example < ActiveRecord::Base
  # end
  #
  # Then, you create an Example instance, which will be given the id 1:
  #
  # example = Example.create!
  #
  # Then, you create a handful of Example instances in a transaction that
  # rolls back:
  #
  # Example.transaction do
  #   Example.create!
  #   Example.create!
  #   Example.create!
  #   raise 'boom'
  # end
  #
  # The transaction aborts and the Example instances are not saved, as one
  # would expect.
  #
  # However, if you then create another Example instance:
  #
  # example2 = Example.create!
  #
  # You'll find that example2's ID is 5, rather than the 2 that you would
  # expect. This is because Postgres does not roll back the sequence used to
  # generate IDs for the Example instances that failed to persist beyond the
  # transaction that was aborted.
  #
  # That's usually not a big deal - all future Example instances will still
  # have unique IDs - but in instances (such as in the case of InventoryBin)
  # where IDs are used in the real world, it may be undesirable to have gaps
  # in the sequence of IDs. In such cases you can use Counter.next to generate
  # sequential numbers that *will* be rolled back in the case of a transaction
  # rollback:
  #
  # class CountingExample < ActiveRecord::Base
  #   before_create do
  #     self.id = Counter.next('counting_example_ids')
  #   end
  # end
  #
  # CountingExample.create! # id: 1
  #
  # CountingExample.transaction do
  #   CountingExample.create! # id: 2, but rolls back
  #   CountingExample.create! # id: 3, but rolls back
  #   CountingExample.create! # id: 4, but rolls back
  #   raise 'boom'
  # end
  #
  # CountingExample.create! # id: 2
  def self.next(name)
    counter = create_or_find_by!(name: name) { |c| c.value = 0 }
    connection.execute("UPDATE #{table_name} SET value = value + 1 WHERE name = #{connection.quote(name)} RETURNING value")[0]['value']
  end
end
