ActiveAdmin.register CertificationIssuance do
  menu parent: 'Certifications', priority: 3

  permit_params [:certification_id, :user_id, :tentative_recipient_name, :issued_at, :certifier_id, :notes]

  config.sort_order = 'issued_at_desc'

  actions :all, except: [:destroy]

  filter :certification
  filter :user_id, as: :search_select_filter, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS
  filter :tentative, as: :boolean, filters: [:eq], label: 'Tentative (not yet connected to a user)'
  filter :tentative_recipient_name
  filter :issued_at
  filter :certifier_id, as: :search_select_filter, url: ->(_) { admin_users_path }, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS

  scope :active, default: true
  scope :revoked
  scope :all

  order_by(:user) do |order_clause|
    "#{CertificationIssuance::USER_NAME_OR_RECIPIENT_SQL} #{order_clause.order}"
  end

  index do
    column(:description) { |certification_issuance| auto_link(certification_issuance)  }
    column(:certification, sortable: 'certifications.name')
    column(:user, sortable: true) { |certification_issuance| auto_link(certification_issuance.user, certification_issuance.name_of_recipient) }
    column('Active (Not Revoked)', &:active)
    column(:user_has_membership) { |certification_issuance| certification_issuance.user&.has_household_membership }
    column(:issued_at)
    column(:certified_by, &:certifier)
  end

  show do
    attributes_table do
      row(:certification)
      row(:user)
      row(:tentative_recipient_name)
      row(:issued_at)
      row(:certifier)
      row(:active)
      if resource.revoked?
        row(:revocation_reason) { |certification_issuance| format_multi_line_text(certification_issuance.revocation_reason) }
      end
      row(:notes) { |certification_issuance| format_multi_line_text(certification_issuance.notes) }
    end
  end

  form do |f|
    f.inputs do
      if f.object.new_record?
        f.object.issued_at = Date.today # TODO: double check the timezone
        f.input :certification
      else
        f.fixed_text 'Certification', auto_link(f.object.certification)
      end
      f.input :user_id, as: :search_select, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS, hint: "The user who is receiving the certification, if they have a user in the system. (If they don't and if you can't create one right now, leave this blank and enter their name into \"Tentative recipient name\".)"
      f.input :tentative_recipient_name, hint: "The name of the person who is receiving the certification, if they don't have a user in the system. Only required if the \"User\" field is left blank. Note that the certification will not grant the recipient any privileges until the \"User\" field is filled in later."
      f.input :issued_at, as: :datepicker, hint: "The date this certification was issued. Leave set to today's date unless you're backfilling old certifications or processing certifications that happened a few days ago."
      f.input :certifier_id, as: :search_select, url: admin_users_path, display_name: 'dropdown_display_name', fields: User::DROPDOWN_SEARCH_FIELDS, hint: 'The user who performed the certification, if known'
      f.fixed_text 'Active', f.object.active ? 'Yes' : 'No'
      if f.object.revoked?
        f.fixed_text 'Revocation Reason', format_multi_line_text(f.object.revocation_reason)
      end
      f.input :notes, hint: 'Any notes to attach to this certification. This will be visible to, and editable by, the area certifiers and staff. A historical record will be kept of any edits.'
    end
    f.actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:certification, :user)
    end
  end

  action_item :publish, only: :show, if: -> { resource.active? } do
    link_to 'Revoke', revoke_admin_certification_issuance_path(resource)
  end

  member_action :revoke, method: [:get, :post] do
    if request.get?
      @page_title = "Revoke #{resource.name_of_recipient}'s certification on #{resource.certification.name}"
      next
    end

    resource.revoke!(current_user, params[:certification_issuance][:revocation_reason])
    flash[:notice] = "#{resource.name_of_recipient}'s certification on #{resource.certification.name} has been revoked."
    redirect_to resource_path(resource), status: :see_other
  end
end
