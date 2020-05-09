# == Schema Information
#
# Table name: badge_reader_manual_users
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  badge_reader_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_badge_reader_manual_users_on_badge_reader_id  (badge_reader_id)
#  index_badge_reader_manual_users_on_user_id          (user_id)
#  index_badge_reader_manual_users_unique              (badge_reader_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (badge_reader_id => badge_readers.id)
#  fk_rails_...  (user_id => users.id)
#
class BadgeReaderManualUser < ApplicationRecord
end
