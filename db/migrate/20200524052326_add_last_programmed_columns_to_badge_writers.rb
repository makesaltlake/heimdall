class AddLastProgrammedColumnsToBadgeWriters < ActiveRecord::Migration[6.0]
  def change
    add_reference :badge_writers, :last_programmed_user, foreign_key: { to_table: :users }
    add_column :badge_writers, :last_programmed_at, :timestamp
  end
end
