ActiveAdmin.register User do
  permit_params :name, :email, :super_user, :password, :password_confirmation, household_user_ids: []

  config.sort_order = 'subscription_created_desc'

  filter :name
  filter :email
  filter :has_household_membership, as: :boolean, filters: [:eq], label: 'Household Has Membership'
  filter :has_multiple_household_members, as: :boolean, filters: [:eq], label: 'Has Household Members'
  filter :current_sign_in_at, label: 'Last Signed In'
  filter :subscription_created
  filter :has_a_badge, as: :boolean, filters: [:eq]
  filter :badge_token_set_at, label: 'Badge Programmed At'
  filter :created_at
  filter :super_user

  index do
    column(:name) { |user| auto_link(user, user.name.presence || '(no name)') }
    column(:email)
    column(:household_has_membership, &:has_household_membership)
    column(:subscription_created)
    column('Last Signed In', :current_sign_in_at)
  end

  show do
    attributes_table do
      row(:name)
      row(:email)
      row(:household_has_membership, &:has_household_membership)
      row(:individual_has_membership, &:subscription_active)
      row(:subscription_id)
      row(:subscription_created)
      row(:super_user)
      row('Last Signed In', &:current_sign_in_at)
      row('Failed Sign In Attempts', &:failed_attempts)
      row('Household members') { |user| user.household_users.order(:name).map { |other_user| auto_link(other_user) }.join('<br/>').html_safe }
      row('Instructs these certifications') { |user| user.instructed_certifications.order(:name).map { |certification| auto_link(certification) }.join('<br/>').html_safe }
      row('Manual access to these badge readers') { |user| user.manual_user_badge_readers.order(:name).map { |badge_reader| auto_link(badge_reader) }.join('<br/>').html_safe }
    end

    panel 'Badge' do
      attributes_table_for resource do
        row(:has_a_badge) do
          if user.badge_token
            status_tag 'Yes'
            text_node " - programmed on #{I18n.l(user.badge_token_set_at)}. "
            text_node link_to('Remove', remove_badge_admin_user_path(resource), method: :post, data: { confirm: "Are you sure you want to remove #{resource.name}'s badge? You won't be able to undo this; their badge (or a new badge) will need to be re-programmed to their account in order to work again. (There is no need to do this for members whose subscriptions have lapsed as their access will be disabled automatically.)" })
          else
            status_tag 'No'
          end
        end
      end

      form method: :post, action: set_currently_programming_user_admin_badge_writers_path do
        span 'Program a new badge for this user using the following badge writer:'

        select name: 'badge_writer[id]' do
          BadgeWriter.all.order(:name).each do |badge_writer|
            option badge_writer.name, value: badge_writer.id
          end
        end

        input type: :hidden, name: 'badge_writer[currently_programming_user_id]', value: resource.id
        input type: :hidden, name: 'authenticity_token', value: form_authenticity_token
        input type: :submit, value: 'Start Programming'
      end
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
    def scoped_collection
      end_of_association_chain.select("users.*, #{User::HAS_HOUSEHOLD_MEMBERSHIP_ATTRIBUTE_SQL}")
    end

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

  member_action :remove_badge, method: :post do
    resource.remove_badge!

    flash[:notice] = "#{resource.name}'s badge has been removed."
    redirect_to resource_path(resource), status: :see_other
  end
end
