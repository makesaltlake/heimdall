ActiveAdmin.register BadgeReaderScan do
  menu parent: 'Badges', priority: 3

  config.sort_order = 'scanned_at_desc'

  actions :index, :show

  filter :badge_reader
  filter :user_id, as: :search_select_filter
  filter :scanned_at

  index do
    column(:description) { |badge_reader_scan| auto_link(badge_reader_scan)  }
    column(:badge_reader, sortable: 'badge_readers.name')
    column(:user, sortable: 'users.name')
    column(:scanned_at)
  end

  show do
    attributes_table do
      row(:badge_reader)
      row(:user)
      row(:scanned_at)
    end
  end
end
