ActiveAdmin.register Certification do
  menu parent: 'Certifications', priority: 1

  permit_params :name, :description, instructor_ids: []

  config.sort_order = 'name_asc'

  filter :name

  index do
    column(:name) { |certification| auto_link(certification) }
    column(:description) { |certification| truncate(certification.description, length: 100, separator: ' ') }
    column(:instructors) { |certification| certification.instructors.order(:name).map { |user| auto_link(user) }.join(', ').html_safe }
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |certification| format_multi_line_text(certification.description) }
      row(:instructors) { |certification| certification.instructors.order(:name).map { |user| auto_link(user) }.join('<br/>').html_safe }
      row('Grants badge reader access to') { |certification| certification.badge_readers.order(:name).map { |badge_reader| auto_link(badge_reader) }.join('<br/>').html_safe }
    end

    paginated_table_panel(
      resource.certification_issuances.active.includes(:user).order('users.name'),
      title: link_to('Current certification holders - click to filter or add', admin_certification_issuances_path({ q: { certification_id_eq: resource.id } })),
      param_name: :issuances_page
    ) do
      column(:name) { |certification_issuance| auto_link(certification_issuance, certification_issuance.user.name) }
      column(:issued_at)
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:description)
      f.input(:instructor_ids, label: 'Instructors', as: :selected_list, url: admin_users_path)
    end
    f.actions
  end
end
