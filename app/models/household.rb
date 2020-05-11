# == Schema Information
#
# Table name: households
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Household < ApplicationRecord
  has_paper_trail

  has_many :users

  # there shouldn't be any of these; this can be used to check if some have
  # been created by mistake
  scope :without_users, -> { includes(:users).where(users: { id: nil }) }
end
