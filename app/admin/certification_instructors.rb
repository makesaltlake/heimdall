ActiveAdmin.register CertificationInstructor do
  menu parent: 'Certifications', priority: 3

  permit_params [:certification_id, :user_id]

  actions :all, except: [:edit, :update]

  filter :certification
  filter :user_id, as: :search_select_filter, label: 'Instructor'

  index do
    column(:description) { |certification_instructor| auto_link(certification_instructor)  }
    column(:certification, sortable: 'certifications.name')
    column(:instructor, sortable: 'users.name', &:user)
  end

  show do
    attributes_table do
      row(:certification)
      row(:user)
      row(:created_at)
    end
  end

  form do |f|
    f.inputs do
      f.input :certification
      f.input :user, input_html: { class: 'select2' }
    end
    f.actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:certification, :user)
    end
  end
end
