class CreateStripeSubscriptions < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_subscriptions do |t|
      t.string :subscription_id_in_stripe, index: true
      t.string :customer_id_in_stripe, index: true
      t.belongs_to :user, foreign_key: true

      t.string :customer_email, index: true
      t.string :customer_name
      t.string :customer_description
      t.string :customer_inferred_name

      t.boolean :active
      t.boolean :unpaid

      t.timestamp :started_at
      t.timestamp :ended_at
      t.timestamp :canceled_at
      t.timestamp :cancel_at

      t.string :plan_name
      t.integer :interval
      t.string :interval_type
      t.integer :interval_amount

      t.timestamps
    end
  end
end
