# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  badge_number           :integer
#  badge_token            :string
#  badge_token_set_at     :datetime
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  inventory_user         :boolean          default(FALSE), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  subscription_active    :boolean          default(FALSE), not null
#  subscription_created   :datetime
#  super_user             :boolean          default(FALSE), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  household_id           :bigint           not null
#  subscription_id        :string
#
# Indexes
#
#  index_users_on_badge_number          (badge_number)
#  index_users_on_badge_token           (badge_token) UNIQUE
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_household_id          (household_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (household_id => households.id)
#
class User < ApplicationRecord
  ALL_HOUSEHOLD_MEMBER_IDS_SQL = '(select household_users.id from users as household_users where household_users.household_id = users.household_id)'
  FELLOW_HOUSEHOLD_MEMBER_IDS_SQL = '(select household_users.id from users as household_users where household_users.household_id = users.household_id and household_users.id != users.id)'

  HAS_HOUSEHOLD_MEMBERSHIP_SQL = 'exists(select household_users.id from users as household_users where household_users.household_id = users.household_id and household_users.subscription_active)'
  HAS_HOUSEHOLD_MEMBERSHIP_ATTRIBUTE_SQL = "#{HAS_HOUSEHOLD_MEMBERSHIP_SQL} as has_household_membership"

  # I swear there has to be a way to do this with vanilla Ransack, or at least
  # without resorting to hand-crafted SQL...
  HAS_SIGNED_A_WAIVER_SQL = 'exists(select waivers.id from waivers where waivers.user_id = users.id)'

  # The fields to allow users to be searched by when selecting a user in a
  # dropdown in the admin UI. If you change this, be sure to update the
  # dropdown_display_name method if you want any of the additional fields to
  # be shown to the user when they're viewing the list of users that matched.
  DROPDOWN_SEARCH_FIELDS = ['id', 'email', 'name']

  # Include default devise modules. Others available are:
  # :confirmable, :registerable, and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable, :timeoutable

  has_paper_trail skip: [:password, :password_confirmation, :encrypted_password, :badge_token]

  has_one_attached :profile_image

  nilify_blanks only: [:email]

  belongs_to :household

  has_many :stripe_subscriptions

  has_many :certification_issuances
  has_many :certification_instructors

  has_many :received_certifications, through: :certification_issuances, source: :certification
  has_many :instructed_certifications, through: :certification_instructors, source: :certification

  has_many :certified_certification_issuances, class_name: 'CertificationIssuance', foreign_key: 'certifier_id', inverse_of: :certifier

  has_many :badge_reader_manual_users
  has_many :badge_scans

  has_many :manual_user_badge_readers, through: :badge_reader_manual_users, source: :badge_reader

  has_many :badge_access_grants

  has_many :waivers

  scope :most_recently_subscribed_first, -> { order("users.subscription_created DESC NULLS LAST") }

  ransacker :has_multiple_household_members, formatter: ActiveModel::Type::Boolean.new.method(:cast) do
    Arel.sql("exists(#{FELLOW_HOUSEHOLD_MEMBER_IDS_SQL})")
  end

  ransacker :has_household_membership, formatter: ActiveModel::Type::Boolean.new.method(:cast) do
    Arel.sql(HAS_HOUSEHOLD_MEMBERSHIP_SQL)
  end

  ransacker :has_a_badge, formatter: ActiveModel::Type::Boolean.new.method(:cast) do
    arel_table[:badge_token].not_eq(nil)
  end

  ransacker :has_signed_a_waiver, formatter: ActiveModel::Type::Boolean.new.method(:cast) do
    Arel.sql(HAS_SIGNED_A_WAIVER_SQL)
  end

  # Associate any unassociated waivers with this user's email address to this user. There's a matching block in Waiver
  # that does the same thing when a new waiver is created.
  after_create do
    Waiver.where(user: nil).where('lower(email) = lower(?)', email).update(user: self)
  end

  def display_name
    name
  end

  # Email addresses are optional - that way household members etc. can be
  # created and given certifications and access even if we don't know the
  # household member's email address.
  def email_required?
    false
  end

  # Since email addresses are optional (which isn't the usual case with
  # Devise), don't allow querying users using a null email address
  def self.find_for_authentication(conditions)
    if conditions[:email].present?
      super
    else
      Rails.logger.info("Tried to query a user for authentication using a nil email address; don't do that")
      nil
    end
  end

  # Household logic. This can probably be simplified, but the gist of what it
  # needs to do is: households should function as anonymous groups of users.
  # Every user belongs to exactly one household and every household has one or
  # more users.

  # The IDs of all users who are in this user's household, not including this
  # user themselves.
  def household_user_ids
    @household_user_ids || household.users.where.not(id: id).pluck(:id)
  end

  # Set the list of IDs of users that should be in this user's household.
  # This doesn't actually make any changes to the users' households until this
  # user is saved.
  def household_user_ids=(ids)
    # cleanup; activeadmin addons's selected_list field type passes ids as
    # strings and passes a blank one as the first argument (which looks like
    # its attempt to ensure a parameter for this association is always passed
    # so as to trigger the removal of all of its values if it's been blanked
    # out in the form, but it doesn't bother removing it if there are in fact
    # items in the association)
    ids = ids.select(&:presence).compact.map { |id| Integer(id) }
    @household_user_ids = ids
  end

  # A relation containing all users that are in this user's household, not
  # including this user themselves.
  def household_users
    User.where(id: household_user_ids)
  end

  # Give each user their own household when they're created
  after_initialize do
    self.household = Household.new if new_record?
  end

  # Destroy our household when we're destroyed if we're the last user in it
  after_destroy do
    household.destroy! if household.users.blank?
  end

  after_save do
    # This is complicated enough that I'm seriously considering writing this
    # project's first tests for it...
    current_household_members = household.users.where.not(id: id).pluck(:id)
    old_household_members = current_household_members - household_user_ids
    new_household_members = household_user_ids - current_household_members

    old_household_members.each do |id|
      # Detach them from our household by putting them into a newly created
      # household
      user = User.find(id)
      user.update!(household: Household.new)
    end

    new_household_members.each do |id|
      # Attach them to our household by first setting our household as theirs...
      user = User.find(id)
      old_household = user.household
      user.update!(household: self.household)

      # ...and then destroying their former household if it no longer has any
      # users.
      old_household.destroy! if old_household.users.blank?
    end

    @household_user_ids = nil
  end

  def has_household_membership
    if attributes.has_key?('has_household_membership')
      attributes['has_household_membership']
    else
      User.where(id: id).select(HAS_HOUSEHOLD_MEMBERSHIP_ATTRIBUTE_SQL).take&.has_household_membership
    end
  end

  # Called by StripeSubscription's #after_save and #after_destroy to update
  # the user to whom the subscription refers
  def regenerate_subscription_attributes
    # Use the most recent active subscription, or the most recent overall if
    # none are active
    most_recent_subscription = stripe_subscriptions.active.most_recently_started_first.first
    most_recent_subscription ||= stripe_subscriptions.most_recently_started_first.first

    update!(
      subscription_active: most_recent_subscription&.active? || false,
      subscription_created: most_recent_subscription&.started_at,
      subscription_id: most_recent_subscription&.subscription_id_in_stripe
    )
  end

  # removes a user's badge from their account. useful when the user's badge has
  # been lost or stolen.
  def remove_badge!
    self.badge_token = nil
    self.badge_token_set_at = nil
    self.save!
  end

  # The name to show when displaying this user in a dropdown. If you change
  # this, be sure to include any additional fields in DROPDOWN_SEARCH_FIELDS.
  def dropdown_display_name
    "#{name} (#{email.presence || 'no email'}, user ##{id})"
  end

  def as_json(options = {})
    super.merge(dropdown_display_name: dropdown_display_name)
  end
end
