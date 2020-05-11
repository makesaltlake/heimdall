# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  badge_number           :string
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  super_user             :boolean          default(FALSE), not null
#  unconfirmed_email      :string
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :timeoutable,, :registerable, and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable

  has_paper_trail skip: [:password, :password_confirmation, :encrypted_password]

  has_many :certification_issuances
  has_many :certification_instructors

  has_many :received_certifications, through: :certification_issuances, source: :certification
  has_many :instructed_certifications, through: :certification_instructors, source: :certification

  has_many :certified_certification_issuances, class_name: 'CertificationIssuance', foreign_key: 'certifier_id', inverse_of: :certifier

  has_many :badge_reader_manual_users
  has_many :badge_reader_scans

  has_many :manual_user_badge_readers, through: :badge_reader_manual_users, source: :badge_reader

  def display_name
    name
  end
end
