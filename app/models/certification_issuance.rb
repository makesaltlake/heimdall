# == Schema Information
#
# Table name: certification_issuances
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE)
#  issued_at         :date
#  notes             :text
#  revocation_reason :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  certification_id  :bigint           not null
#  certifier_id      :bigint
#  revoked_by_id     :bigint
#  user_id           :bigint           not null
#
# Indexes
#
#  index_certification_issuances_on_certification_id              (certification_id)
#  index_certification_issuances_on_certification_id_and_user_id  (certification_id,user_id) UNIQUE WHERE (active = true)
#  index_certification_issuances_on_certifier_id                  (certifier_id)
#  index_certification_issuances_on_revoked_by_id                 (revoked_by_id)
#  index_certification_issuances_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (certification_id => certifications.id)
#  fk_rails_...  (certifier_id => users.id)
#  fk_rails_...  (revoked_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class CertificationIssuance < ApplicationRecord
  has_paper_trail

  belongs_to :certification
  belongs_to :user

  belongs_to :certifier, class_name: 'User', inverse_of: :certified_certification_issuances, optional: true
  belongs_to :revoked_by, class_name: 'User', optional: true

  scope :active, -> { where(active: true) }
  scope :revoked, -> { where(active: false) }

  # validate that the user doesn't already have an active copy of this certification
  validate do
    if active? && user.certification_issuances.where(certification: certification, active: true).where.not(id: id).exists?
      errors.add(:user, 'is already an active recipient of this certification')
    end
  end

  def revoked?
    !active?
  end

  def display_name
    "#{user.name} #{!active? ? 'formerly ' : ''}certified on #{certification.name}"
  end

  def revoke!(revoked_by, reason)
    raise "can't revoke an already-revoked certificate issuance" if revoked?
    update!(active: false, revocation_reason: reason, revoked_by: revoked_by)
  end
end
