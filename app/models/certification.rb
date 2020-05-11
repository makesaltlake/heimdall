# == Schema Information
#
# Table name: certifications
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Certification < ApplicationRecord
  has_paper_trail

  has_many :certification_issuances
  has_many :certification_instructors

  has_many :certified_users, through: :certification_issuances, source: :user
  has_many :instructors, through: :certification_instructors, source: :user

  has_many :badge_reader_certifications

  has_many :badge_readers, through: :badge_reader_certifications
end
