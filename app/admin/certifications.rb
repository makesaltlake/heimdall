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

    puts "first instance: #{self.class}"
    paginated_table_panel(resource.certification_instructors.includes(:user).order('users.name'), title: 'Instructors', param_name: :instructor_page) do
      column(:name) { |certification_instructor| auto_link(certification_instructor, certification_instructor.user.name) }
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
