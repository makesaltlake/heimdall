ActiveAdmin.register CertificationIssuance do
  menu parent: 'Certifications', priority: 2

  permit_params [:notes]

  index do

  end

  show do

  end

  form do |f|
    f.inputs do
      if f.object.new_record?
        f.input :certification
        f.input :user
      else
        f.fixed_text 'Certification', auto_link(f.object.certification)
        f.fixed_text 'User', auto_link(f.object.user)
      end
      f.input :active
      f.input :revocation_reason
      f.fixed_text 'Foo', 'Bar Baz'
    end
    f.actions
  end

  member_action :revoke, method: [:get, :post] do
    return if request.get?

    resource.revoke!(current_user, params[:reason])
    flash[:notice] = "#{resource.user.name}'s certification on #{resource.certification.name} has been revoked."
  end
end
