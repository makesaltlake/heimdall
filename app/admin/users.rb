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
      row(:super_user)
      row('Last Signed In', &:current_sign_in_at)
      row('Failed Sign In Attempts', &:failed_attempts)
      row('Household members') { |user| user.household_users.order(:name).map { |other_user| auto_link(other_user) }.join('<br/>').html_safe }
      row('Instructs these certifications') { |user| user.instructed_certifications.order(:name).map { |certification| auto_link(certification) }.join('<br/>').html_safe }
      row('Manual access to these badge readers') { |user| user.manual_user_badge_readers.order(:name).map { |badge_reader| auto_link(badge_reader) }.join('<br/>').html_safe }
    end

    paginated_table_panel(
      resource.stripe_subscriptions.order(started_at: :desc),
      title: 'Subscriptions',
      param_name: :subscriptions_page
    ) do
      column('Stripe ID') { |stripe_subscription| a(stripe_subscription.subscription_id_in_stripe, href: StripeUtils.dashboard_url(Stripe::Subscription, stripe_subscription.subscription_id_in_stripe)) }
      column(:plan_name)
      column(:plan, &:plan_label)
      column(:status) do |stripe_subscription|
        if stripe_subscription.active && stripe_subscription.cancel_at
          status_tag 'pending cancellation', class: :yes
        elsif stripe_subscription.active
          status_tag 'active', class: :green
        elsif stripe_subscription.unpaid
          status_tag 'unpaid', class: :orange
        else
          status_tag 'cancelled'
        end
      end
      column(:started_at)
      column(:ended_at)
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
      resource.badge_access_grants.includes(:badge_reader).order('badge_readers.name'),
      title: 'Currently has access to these badge readers',
      param_name: :badge_access_grants_page
    ) do
      column(:badge_reader)
      column(:reason, &:access_reason)
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
      password_blank_action = f.object.new_record? ? "leave their password unset (they'll have to reset it before they can log in)" : 'leave their password unchanged'
      f.input(:password, hint: "Type a new password for this user here, or leave blank to #{password_blank_action}")
      f.input(:password_confirmation, hint: 'Retype the new password here')
      f.input(:household_user_ids, label: 'Household members', as: :selected_list, url: admin_users_path, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS)
    end
    f.actions
  end

  before_create do |user|
    # Set a randomly generated password for the user if one wasn't specified -
    # effectively preventing them from logging in if/until they reset their
    # password.
    unless user.password.present? || user.password_confirmation.present?
      user.password = Devise.friendly_token
      user.password_confirmation = nil
    end
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

  action_item :begin_merge, only: :show do
    link_to 'Merge User', begin_merge_admin_user_path(resource)
  end

  member_action :begin_merge, method: :get do
    @page_title = "Merge a user into #{resource.name}"
  end

  member_action :review_merge, method: :get do
    source_user_id = params[:user][:user_id]
    unless source_user_id.present?
      flash[:warning] = "Please select a user to merge into this user."
      next redirect_back(fallback_location: begin_merge_admin_user_path(resource))
    end

    @source_user = User.find(source_user_id)
    authorize! :merge_user, @source_user

    if @source_user == resource
      flash[:warning] = "You can't merge a user with themselves. Please select another user."
      next redirect_back(fallback_location: begin_merge_admin_user_path(resource))
    end

    @page_title = "Merge #{@source_user.name} into #{resource.name}"
  end

  member_action :merge, method: :post do
    @source_user = User.find(params[:source_user_id])
    authorize! :merge_user, @source_user

    UserMergeService.new(@source_user, resource, current_user).run!

    redirect_to merge_complete_admin_user_path(resource, source_user_id: @source_user.id, source_user_name: @source_user.name)
  end

  member_action :merge_complete, method: :get do
    resource # to force authorization

    @page_title = "Merge complete"
    @source_user_id = params[:source_user_id]
    @source_user_name = params[:source_user_name]
  end
end
