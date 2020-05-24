# == Schema Information
#
# Table name: badge_reader_scans
#
#  id              :bigint           not null, primary key
#  scanned_at      :datetime
#  submitted_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  badge_reader_id :bigint
#  user_id         :bigint
#
# Indexes
#
#  index_badge_reader_scans_on_badge_reader_id  (badge_reader_id)
#  index_badge_reader_scans_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (badge_reader_id => badge_readers.id)
#  fk_rails_...  (user_id => users.id)
#
class BadgeReaderScan < ApplicationRecord
  has_paper_trail

  belongs_to :badge_reader
  # usually required, but optional in case a badge scan got queued up and
  # submitted after the user's badge had been rotated. perhaps we should store
  # a historical record of a user's badge tokens so that we can still correlate
  # them in such a case...
  belongs_to :user, optional: true
end
