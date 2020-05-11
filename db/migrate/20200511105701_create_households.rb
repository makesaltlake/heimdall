class CreateHouseholds < ActiveRecord::Migration[6.0]
  def change
    create_table :households do |t|
      # no columns. easy peasy.
      t.timestamps
    end

    add_reference :users, :household, foreign_key: true

    reversible do |dir|
      dir.up do
        # define these here so that changes to the User or Household models don't
        # break this migration down the line
        user_class = Class.new(ActiveRecord::Base) do
          self.table_name = 'users'
        end
        household_class = Class.new(ActiveRecord::Base) do
          self.table_name = 'households'
        end

        user_class.all.each do |user|
          user.update!(household_id: household_class.create!.id)
        end
      end

      # nothing special to do when migrating down
    end

    change_column_null :users, :household_id, false
  end
end
