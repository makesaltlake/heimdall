ActiveAdmin.register BadgeScan do
  menu parent: 'Badges', priority: 3

  config.sort_order = 'scanned_at_desc'

  actions :index, :show

  filter :badge_reader
  filter :user_id, as: :search_select_filter, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS
  filter :badge_number_equals, label: 'Badge Number'
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
      row(:badge_number) { |badge_scan| reveal_link("Badge number: #{badge_scan.badge_number || "unknown"}") }
      row(:authorized)
      row(:scanned_at)
    end
  end
end
