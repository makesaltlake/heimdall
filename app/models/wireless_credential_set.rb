# == Schema Information
#
# Table name: wireless_credential_sets
#
#  id         :bigint           not null, primary key
#  password   :string           not null
#  ssid       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class WirelessCredentialSet < ApplicationRecord
  has_paper_trail

  validates :ssid, presence: true
  validates :password, presence: true

  scope :most_recent_first, -> { order(created_at: :desc) }

  after_save :notify_devices_about_changes
  after_destroy :notify_devices_about_changes

  def notify_devices_about_changes
    after_transaction_commit do
      BadgeReader.all.find_each do |badge_reader|
        BadgeReaderChannel.broadcast_to(badge_reader, { type: 'new_wireless_credentials' })
      end
      BadgeWriter.all.find_each do |badge_writer|
        BadgeWriterChannel.broadcast_to(badge_writer, { type: 'new_wireless_credentials' })
      end
    end
  end

  def display_name
    "Wireless credentials for SSID #{ssid.inspect}"
  end
end
