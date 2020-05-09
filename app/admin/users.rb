ActiveAdmin.register User do
  permit_params :name, :email, :super_user, :password, :password_confirmation

  filter :name
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  index do
    column(:name) { |user| auto_link(user, user.name.presence || '(no name)') }
    column(:email)
    column('Last Signed In', :current_sign_in_at)
  end

  show do
    attributes_table do
      row(:name)
      row(:email)
      row(:super_user)
      row('Last Signed In', &:current_sign_in_at)
      row('Failed Sign In Attempts', &:failed_attempts)
    end

    paginated_table_panel(
      resource.certification_instructors.includes(:certification).order('certifications.name'),
      title: link_to('Instructor of these certifications - click to filter or add', admin_certification_instructors_path({ q: { user_id_eq: resource.id } })),
      param_name: :instructors_page
    ) do
      column(:name) { |certification_instructor| auto_link(certification_instructor, certification_instructor.certification.name) }
    end

    paginated_table_panel(
      resource.certification_issuances.active.includes(:certification).order('certifications.name'),
      title: link_to('Currently holds these certifications - click to filter or add', admin_certification_issuances_path({ q: { user_id_eq: resource.id } })),
      param_name: :issuances_page
    ) do
      column(:name) { |certification_issuance| auto_link(certification_issuance, certification_issuance.certification.name) }
      column(:issued_at)
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:email)
      if user == current_user
        # Users can't change their own super user status (so a super user doesn't
        # accidentally demote themselves)
        f.input(:super_user, input_html: { disabled: true }, hint: "You can't change your own super user status.")
      else
        f.input(:super_user)
      end
      f.input(:password, hint: 'Type a new password for this user here, or leave blank to leave their password unchanged')
      f.input(:password_confirmation, hint: 'Retype the new password here')
    end
    f.actions
  end

  controller do
    def update
      # Don't try to update the user's password if no password is specified.
      # TODO: consider ripping out the ability to set passwords directly
      # altogether and only allow passwords to be reset.
      password_fields = [:password, :password_confirmation]
      if password_fields.all? { |f| params[:user][f].blank? }
        password_fields.each { |f| params[:user].delete(f) }
      end

      # Users can't change their own super user status (so a super user doesn't
      # accidentally demote themselves)
      params[:user].delete(:super_user) if params[:id] == current_user.id

      super
    end
  end

end
