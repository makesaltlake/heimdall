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

  def display_name
    "Wireless credentials for SSID #{ssid.inspect}"
  end
end
