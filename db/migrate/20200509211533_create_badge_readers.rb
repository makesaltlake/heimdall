class CreateBadgeReaders < ActiveRecord::Migration[6.0]
  def change
    create_table :badge_readers do |t|
      t.string :name
      t.text :description
      t.string :api_token

      t.timestamps
    end

    create_table :badge_reader_certifications do |t|
      t.belongs_to :badge_reader, foreign_key: true, null: false
      t.belongs_to :certification, foreign_key: true, null: false

      t.timestamps
    end

    create_table :badge_reader_manual_users do |t|
      t.belongs_to :badge_reader, foreign_key: true, null: false
      t.belongs_to :user, foreign_key: true, null: false

      t.timestamps
    end

    create_table :badge_reader_scans do |t|
      t.belongs_to :badge_reader, foreign_key: true
      t.belongs_to :user, foreign_key: true
      t.timestamp :scanned_at
      t.timestamp :submitted_at

      t.timestamps
    end

    add_column :users, :badge_number, :string

    add_index :badge_reader_certifications, [:badge_reader_id, :certification_id], unique: true, name: 'index_badge_reader_certifications_unique'
    add_index :badge_reader_manual_users, [:badge_reader_id, :user_id], unique: true, name: 'index_badge_reader_manual_users_unique'
  end
end
