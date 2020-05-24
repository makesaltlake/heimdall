class AddBadgeWriterTablesAndColumns < ActiveRecord::Migration[6.0]
  def change
    create_table :badge_writers do |t|
      t.string :name
      t.text :description
      t.string :api_token
      t.timestamp :api_token_regenerated_at
      t.belongs_to :currently_programming_user, foreign_key: { to_table: :users }
      t.timestamp :currently_programming_user_until

      t.timestamps
    end

    add_column :users, :badge_token, :string, index: true
    add_column :users, :badge_token_set_at, :timestamp, index: true
  end
end
