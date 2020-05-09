# == Schema Information
#
# Table name: badge_readers
#
#  id          :bigint           not null, primary key
#  api_token   :string
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class BadgeReader < ApplicationRecord
end
