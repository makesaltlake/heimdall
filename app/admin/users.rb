ActiveAdmin.register User do
  permit_params :name, :email, :super_user, :password, :password_confirmation, household_user_ids: []

  filter :name
  filter :email
  filter :has_multiple_household_members, as: :boolean, filters: [:eq]
  filter :current_sign_in_at, label: 'Last Signed In'
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
      row('Household members') { |user| user.household_users.order(:name).map { |other_user| auto_link(other_user) }.join('<br/>').html_safe }
      row('Instructs these certifications') { |user| user.instructed_certifications.order(:name).map { |certification| auto_link(certification) }.join('<br/>').html_safe }
      row('Manual access to these badge readers') { |user| user.manual_user_badge_readers.order(:name).map { |badge_reader| auto_link(badge_reader) }.join('<br/>').html_safe }
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
      f.input(:household_user_ids, label: 'Household members', as: :selected_list, url: admin_users_path)
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
