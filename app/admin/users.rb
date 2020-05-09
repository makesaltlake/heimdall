ActiveAdmin.register User do
  permit_params :name, :email, :super_user, :password, :password_confirmation

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
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:email)
      f.input(:super_user)
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

      super
    end
  end

end
