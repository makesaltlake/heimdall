class MakeUserEmailOptional < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:users, :email, true)
    change_column_default(:users, :email, nil)
  end
end
