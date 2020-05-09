# == Schema Information
#
# Table name: badge_reader_certifications
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  badge_reader_id  :bigint           not null
#  certification_id :bigint           not null
#
# Indexes
#
#  index_badge_reader_certifications_on_badge_reader_id   (badge_reader_id)
#  index_badge_reader_certifications_on_certification_id  (certification_id)
#  index_badge_reader_certifications_unique               (badge_reader_id,certification_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (badge_reader_id => badge_readers.id)
#  fk_rails_...  (certification_id => certifications.id)
#
class BadgeReaderCertification < ApplicationRecord
  belongs_to :badge_reader
  belongs_to :certification
end
