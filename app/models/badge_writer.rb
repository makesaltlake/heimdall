# == Schema Information
#
# Table name: badge_writers
#
#  id                            :bigint           not null, primary key
#  api_token                     :string
#  api_token_regenerated_at      :datetime
#  currently_programming_until   :datetime
#  description                   :text
#  last_programmed_at            :datetime
#  name                          :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  currently_programming_user_id :bigint
#  last_programmed_user_id       :bigint
#
# Indexes
#
#  index_badge_writers_on_currently_programming_user_id  (currently_programming_user_id)
#  index_badge_writers_on_last_programmed_user_id        (last_programmed_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (currently_programming_user_id => users.id)
#  fk_rails_...  (last_programmed_user_id => users.id)
#
class BadgeWriter < ApplicationRecord
  API_TOKEN_LENGTH = 40
  # How long a badge can be programmed for a user using a badge writer before
  # the badge writer times out
  CAN_PROGRAM_FOR = 5.minutes

  class DuplicateBadgeTokenError < StandardError; end

  has_paper_trail skip: [:api_token]

  belongs_to :currently_programming_user, class_name: 'User', optional: true
  belongs_to :last_programmed_user, class_name: 'User', optional: true

  # Give every badge writer an API token on creation.
  # Also, BadgeReader and BadgeWriter share the same API token code; if we find
  # ourselves reusing that in a third model, we should consider breaking that
  # out into a module shared between the three.
  after_initialize do
    generate_api_token if new_record?
  end

  def regenerate_api_token!
    generate_api_token
    save!
  end

  def generate_api_token
    self.api_token = SecureRandom.hex(API_TOKEN_LENGTH / 2) # because SecureRandom.hex expects a number of bytes, not characters
    self.api_token_regenerated_at = Time.now
  end

  # called to set the user whose badge will be programmed when program_badge!
  # is called
  def set_currently_programming_user!(user)
    self.currently_programming_user = user
    self.currently_programming_until = Time.now + CAN_PROGRAM_FOR
    save!
  end

  # called to cancel the current programming session
  def cancel_programming!
    self.currently_programming_user = nil
    self.currently_programming_until = nil
    save!
  end

  # called to program a badge for the currently_programming_user. returns that
  # user if programming was successful, or nil if there is no such user or if
  # the time to program a badge for that user has expired.
  def program_badge!(badge_token)
    return unless programming?

    user = TransactionRetry.run do
      User.transaction do
        user = self.currently_programming_user
        now = Time.now

        raise DuplicateBadgeTokenError.new if User.where(badge_token: badge_token).where.not(id: user.id).exists?

        user.badge_token = badge_token
        user.badge_token_set_at = now
        user.save!

        self.currently_programming_user = nil
        self.currently_programming_until = nil
        self.last_programmed_user = user
        self.last_programmed_at = now
        self.save!

        user
      end
    end

    user
  end

  def programming?
    currently_programming_user && currently_programming_until > Time.now
  end

  def firmware_bundles
    FirmwareBundle.where(device_type: 'badge_writer')
  end
end
