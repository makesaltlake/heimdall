# == Schema Information
#
# Table name: badge_scans
#
#  id              :bigint           not null, primary key
#  authorized      :boolean          default(TRUE)
#  badge_number    :integer
#  badge_token     :string
#  scanned_at      :datetime
#  submitted_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  badge_id        :string
#  badge_reader_id :bigint
#  user_id         :bigint
#
# Indexes
#
#  index_badge_scans_on_authorized       (authorized)
#  index_badge_scans_on_badge_id         (badge_id)
#  index_badge_scans_on_badge_reader_id  (badge_reader_id)
#  index_badge_scans_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (badge_reader_id => badge_readers.id)
#  fk_rails_...  (user_id => users.id)
#
class BadgeScan < ApplicationRecord
  has_paper_trail skip: [:badge_token]

  belongs_to :badge_reader
  # usually required, but optional in case a badge scan got queued up and
  # submitted after the user's badge had been rotated or for scans where the
  # badge didn't have a valid associated user
  belongs_to :user, optional: true

  scope :authorized, -> { where(authorized: true) }
  scope :rejected, -> { where(authorized: false) }
end
