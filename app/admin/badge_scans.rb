ActiveAdmin.register BadgeScan do
  menu parent: 'Badges', priority: 3

  config.sort_order = 'scanned_at_desc'

  actions :index, :show

  filter :badge_reader
  filter :user_id, as: :search_select_filter
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
      row(:user) do
        if resource.user
          auto_link(resource.user)
        elsif resource.badge_token
          "None. A badge token was provided but it couldn't be matched to a user in the system."
        end
      end
      row('Badge ID', &:badge_id)
      row(:authorized)
      row(:scanned_at)
    end
  end
end
