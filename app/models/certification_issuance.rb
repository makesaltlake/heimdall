# == Schema Information
#
# Table name: certification_issuances
#
#  id                :bigint           not null, primary key
#  active            :boolean
#  issued_at         :datetime
#  notes             :text
#  revocation_reason :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  certification_id  :bigint           not null
#  certifier_id      :bigint
#  user_id           :bigint           not null
#
# Indexes
#
#  index_certification_issuances_on_certification_id              (certification_id)
#  index_certification_issuances_on_certification_id_and_user_id  (certification_id,user_id) UNIQUE
#  index_certification_issuances_on_certifier_id                  (certifier_id)
#  index_certification_issuances_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (certification_id => certifications.id)
#  fk_rails_...  (certifier_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class CertificationIssuance < ApplicationRecord
  has_paper_trail

  belongs_to :certification
  belongs_to :user

  belongs_to :certifier, class_name: 'User', inverse_of: :certified_certification_issuances

  def display_name
    "#{user.name} #{!active? && 'previously '}certified on #{certification.name}"
  end
end
