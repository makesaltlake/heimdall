# == Schema Information
#
# Table name: waivers
#
#  id                :bigint           not null, primary key
#  email             :string
#  fields            :jsonb
#  signed_at         :datetime
#  user_id           :bigint
#  waiver_forever_id :string
#
# Indexes
#
#  index_waivers_on_email              (email)
#  index_waivers_on_signed_at          (signed_at)
#  index_waivers_on_user_id            (user_id)
#  index_waivers_on_waiver_forever_id  (waiver_forever_id)
#

class Waiver < ApplicationRecord
  has_paper_trail

  belongs_to :user, optional: true

  # Associate this waiver with a user with a matching email address, if one exists and if this waiver isn't already
  # associated with a user. There's a matching block in User that does the same thing when a new user is created.
  before_create do
    if email && !user_id
      user = User.find_for_authentication(email: email.downcase)
      self.user = user if user
    end
  end

  ransacker :has_a_user, formatter: ActiveModel::Type::Boolean.new.method(:cast) do
    arel_table[:user_id].not_eq(nil)
  end

  def display_name
    date_string = " on #{I18n.l(signed_at.to_date)}" if signed_at
    name_string = " by #{name}" if name

    if date_string || name_string
      "Waiver signed#{date_string}#{name_string}"
    else
      "Waiver"
    end
  end
end
