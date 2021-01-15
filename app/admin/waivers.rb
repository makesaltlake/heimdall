ActiveAdmin.register Waiver do
  config.sort_order = 'signed_at_desc'

  menu priority: 14

  actions :all, except: [:new, :create]

  permit_params :user_id

  filter :name
  filter :email
  filter :user_id, label: 'Associated user', as: :search_select_filter, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS
  filter :has_a_user, label: 'Has an associated user', as: :boolean, filters: [:eq]
  filter :signed_at
  filter :waiver_forever_id, label: 'Waiver Forever ID'

  index do
    column(:waiver) { |waiver| auto_link(waiver) }
    column(:signer, sortable: :name, &:name)
    column(:email)
    column(:signed_at)
    column(:associated_user, sortable: :user, &:user)
  end

  show do
    attributes_table do
      row(:signer, &:name)
      row(:email)
      row(:signed_at)
      row(:associated_user, &:user)
      row('WaiverForever ID') do
        text_node link_to(waiver.waiver_forever_id, WaiverForeverUtils.waiver_url(waiver.waiver_forever_id))
        text_node " - Click to view on WaiverForever"
      end
    end

    attributes_table title: "Custom Fields" do
      waiver.fields&.each do |field|
        row(field['title']) { field['value'] }
      end
    end
  end

  form do |f|
    f.inputs do
      f.input(:user_id, label: 'Associated user', as: :search_select, url: admin_users_path, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS)
    end
    f.actions
  end
end
