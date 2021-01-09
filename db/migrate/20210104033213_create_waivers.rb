class CreateWaivers < ActiveRecord::Migration[6.0]
  def change
    create_table :waivers do |t|
      t.string :name, index: true
      t.string :email, index: true
      t.string :waiver_forever_id, index: true
      t.timestamp :signed_at, index: true
      t.jsonb :fields

      t.belongs_to :user
    end
  end
end
