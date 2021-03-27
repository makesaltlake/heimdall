class CreateCounters < ActiveRecord::Migration[6.0]
  def change
    create_table :counters do |t|
      t.string :name, index: { unique: true }
      t.integer :value, limit: 8

      t.timestamps
    end
  end
end
