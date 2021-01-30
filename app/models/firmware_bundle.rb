# == Schema Information
#
# Table name: firmware_bundles
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(FALSE), not null
#  description :text
#  device_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_firmware_bundles_on_active                        (active)
#  index_firmware_bundles_on_device_type                   (device_type)
#  index_firmware_bundles_only_one_active_for_device_type  (device_type) WHERE active
#

class FirmwareBundle < ApplicationRecord
  has_paper_trail

  DEVICE_TYPE_LABELS_TO_VALUES = { 'Badge Reader' => 'badge_reader', 'Badge Writer': 'badge_writer' }
  DEVICE_TYPE_VALUES_TO_LABELS = DEVICE_TYPE_LABELS_TO_VALUES.invert

  enum device_type: { badge_reader: 'badge_reader', badge_writer: 'badge_writer' }

  has_one_attached :firmware_blob

  validates :device_type, presence: true
  validates :device_type, uniqueness: { scope: :active, message: "can't be activated because another firmware bundle for this device type is already active" }, if: :active?

  validate do
    errors[:firmware_blob] << 'is required' unless firmware_blob.attached?
  end

  before_destroy do
    raise "Can't destroy an active firmware bundle; activate another one first" if active?
  end

  scope :active, -> { where(active: true) }
  scope :inactive, ->  { where(active: false) }

  def display_name
    "Firmware bundle uploaded on #{I18n.l(created_at)}"
  end

  def device_type_label
    DEVICE_TYPE_VALUES_TO_LABELS[device_type]
  end

  def activate!
    return if active? # No need to activate if we're already the active firmware bundle

    TransactionRetry.transaction do
      FirmwareBundle.active.find_by(device_type: device_type)&.update!(active: false)
      update!(active: true)

      # Needs to be in an after_transaction_commit block instead of just outside of the TransactionRetry.transaction
      # block in case the call to `activate!` was wrapped in a parent transaction - we only want to run this after that
      # transaction has finished if so
      after_transaction_commit do
        BadgeReader.all.find_each do |badge_reader|
          BadgeReaderChannel.broadcast_to(badge_reader, { type: 'new_firmware' })
        end
        BadgeWriter.all.find_each do |badge_writer|
          BadgeWriterChannel.broadcast_to(badge_writer, { type: 'new_firmware' })
        end
      end
    end
  end
end
