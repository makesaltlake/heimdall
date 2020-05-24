class RenameBadgeWritersCurrentlyProgrammingUserUntilToCurrentlyProgrammingUntil < ActiveRecord::Migration[6.0]
  def change
    rename_column :badge_writers, :currently_programming_user_until, :currently_programming_until
  end
end
