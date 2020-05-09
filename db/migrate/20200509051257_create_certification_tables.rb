class CreateCertificationTables < ActiveRecord::Migration[6.0]
  def change
    create_table :certifications do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    create_table :certification_instructors do |t|
      t.belongs_to :certification, foreign_key: true, null: false
      t.belongs_to :user, index: true, foreign_key: true, null: false

      t.timestamps
    end

    create_table :certification_issuances do |t|
      t.belongs_to :certification, foreign_key: true, null: false
      t.belongs_to :user, index: true, foreign_key: true, null: false

      t.timestamp :issued_at
      t.boolean :active
      t.belongs_to :certifier, foreign_key: { to_table: :users }

      t.text :notes
      t.text :revocation_reason

      t.timestamps
    end

    add_index :certification_instructors, [:certification_id, :user_id], unique: true
    add_index :certification_issuances, [:certification_id, :user_id], unique: true
  end
end
