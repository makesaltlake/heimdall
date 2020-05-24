# == Schema Information
#
# Table name: badge_writers
#
#  id                               :bigint           not null, primary key
#  api_token                        :string
#  api_token_regenerated_at         :datetime
#  currently_programming_user_until :datetime
#  description                      :text
#  name                             :string
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  currently_programming_user_id    :bigint
#
# Indexes
#
#  index_badge_writers_on_currently_programming_user_id  (currently_programming_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (currently_programming_user_id => users.id)
#
class BadgeWriter < ApplicationRecord
end
