ActiveAdmin.register BadgeScan do
  menu parent: 'Badges', priority: 3

  config.sort_order = 'scanned_at_desc'

  actions :index, :show

  filter :badge_reader
  filter :user_id, as: :search_select_filter, display_name: 'name_and_email'
  filter :badge_id, label: 'Badge ID'
  filter :scanned_at

  scope :authorized, default: true
  scope :rejected
  scope :all

  index do
    column(:description) { |badge_scan| auto_link(badge_scan)  }
    column(:badge_reader, sortable: 'badge_readers.name')
    column(:user, sortable: 'users.name')
    column(:authorized)
    column(:scanned_at)
  end

  show do
    attributes_table do
      row(:badge_reader)
      row(:user)
      row('Badge ID', &:badge_id)
      row(:badge_token) { '[hidden]' if resource.badge_token }
      row(:authorized)
      row(:scanned_at)
    end
  end
end
