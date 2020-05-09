ActiveAdmin.register Certification do
  menu parent: 'Certifications', priority: 1

  permit_params :name, :description

  filter :name

  index do
    column(:name) { |certification| auto_link(certification) }
    column(:description)
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |certification| format_multi_line_text(certification.description) }
    end

    paginated_table_panel(
      resource.certification_instructors.includes(:user).order('users.name'),
      title: link_to('Instructors - click to filter', admin_certification_instructors_path({ q: { certification_id_eq: resource.id } })),
      param_name: :instructors_page
    ) do
      column(:name) { |certification_instructor| auto_link(certification_instructor, certification_instructor.user.name) }
    end

    paginated_table_panel(
      resource.certification_issuances.active.includes(:user).order('users.name'),
      title: link_to('Active recipients - click to filter', admin_certification_issuances_path({ q: { certification_id_eq: resource.id } })),
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
    end
    f.actions
  end
end
