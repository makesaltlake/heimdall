# == Schema Information
#
# Table name: stripe_subscriptions
#
#  id                        :bigint           not null, primary key
#  active                    :boolean
#  cancel_at                 :datetime
#  canceled_at               :datetime
#  customer_description      :string
#  customer_email            :string
#  customer_id_in_stripe     :string
#  customer_inferred_name    :string
#  customer_name             :string
#  ended_at                  :datetime
#  interval                  :integer
#  interval_amount           :integer
#  interval_type             :string
#  plan_name                 :string
#  started_at                :datetime
#  subscription_id_in_stripe :string
#  unpaid                    :boolean
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  user_id                   :bigint
#
# Indexes
#
#  index_stripe_subscriptions_on_customer_email             (customer_email)
#  index_stripe_subscriptions_on_customer_id_in_stripe      (customer_id_in_stripe)
#  index_stripe_subscriptions_on_subscription_id_in_stripe  (subscription_id_in_stripe)
#  index_stripe_subscriptions_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class StripeSubscription < ApplicationRecord
  has_paper_trail

  belongs_to :user

  scope :most_recently_started_first, -> { order(started_at: :desc) }
  scope :active, -> { where(active: true) }
  scope :unpaid, -> { where(unpaid: true) }

  after_save :regenerate_user
  after_destroy :regenerate_user

  # Regenerate cached attributes on this subscription's user and previous user
  def regenerate_user
    user&.regenerate_subscription_attributes
    User.find_by(id: user_id_before_last_save)&.regenerate_subscription_attributes if user_id_previously_changed?
  end

  def plan_label
    suffix = interval_type
    suffix = "#{interval} #{interval_type}s" if interval > 1
    "#{SynchrotronService.format_currency(interval_amount)}/#{suffix}"
  end
end
