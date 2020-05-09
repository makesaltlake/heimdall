# == Schema Information
#
# Table name: certification_instructors
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  certification_id :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_certification_instructors_on_certification_id              (certification_id)
#  index_certification_instructors_on_certification_id_and_user_id  (certification_id,user_id) UNIQUE
#  index_certification_instructors_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (certification_id => certifications.id)
#  fk_rails_...  (user_id => users.id)
#
class CertificationInstructor < ApplicationRecord
  has_paper_trail

  belongs_to :certification
  belongs_to :user

  def display_name
    "#{user.name} as instructor for #{certification.name}"
  end
end
