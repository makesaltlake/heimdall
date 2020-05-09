ActiveAdmin.register CertificationIssuance do
  menu parent: 'Certifications', priority: 2

  permit_params [:certification_id, :user_id, :issued_at, :certifier_id, :notes]

  actions :all, except: [:destroy]

  filter :certification
  filter :user_id, as: :search_select_filter
  filter :active

  scope :active, default: true
  scope :revoked
  scope :all

  index do
    column(:description) { |certification_issuance| auto_link(certification_issuance)  }
    column(:certification, sortable: 'certifications.name')
    column(:user, sortable: 'users.name')
    column(:active)
    column(:issued_at)
    column(:certified_by, &:certifier)
  end

  show do
    attributes_table do
      row(:certification)
      row(:user)
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
        f.input :user, input_html: { class: 'select2' }, hint: 'The user who is receiving the certification'
      else
        f.fixed_text 'Certification', auto_link(f.object.certification)
        f.fixed_text 'User', auto_link(f.object.user)
      end
      f.input :issued_at, as: :datepicker, hint: "The date this certification was issued. Leave set to today's date unless you're backfilling old certifications or processing certifications that happened a few days ago."
      f.input :certifier, input_html: { class: 'select2' }, hint: 'The user who performed the certification'
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
      @page_title = "Revoke #{resource.user.name}'s certification on #{resource.certification.name}"
      return
    end

    resource.revoke!(current_user, params[:certification_issuance][:revocation_reason])
    flash[:notice] = "#{resource.user.name}'s certification on #{resource.certification.name} has been revoked."
    redirect_to resource_path(resource), status: :see_other
  end
end
