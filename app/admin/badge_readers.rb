ActiveAdmin.register BadgeReader do
  REGENERATE_API_TOKEN_WARNING = "WARNING: Regenerating a badge reader's API token will cause it to stop working until the new API token has been entered in. Are you sure you want to regenerate this badge reader's API token?"

  menu parent: 'Badge Readers', priority: 1

  permit_params :name, :description, :restricted_access, certification_ids: [], manual_user_ids: []

  filter :name

  index do
    column(:name) { |badge_reader| auto_link(badge_reader) }
    column(:description)
    column(:certifications) { |badge_reader| badge_reader.certifications.order(:name).map { |certification| auto_link(certification) }.join(', ').html_safe }
    column(:manual_users) { |badge_reader| badge_reader.manual_users.order(:name).map { |user| auto_link(user) }.join(', ').html_safe }
    column('Prevent access by the general membership', &:restricted_access)
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |badge_reader| format_multi_line_text(badge_reader.description) }
      row(:api_token) { |badge_reader| "#{link_to('Reveal', reveal_api_token_admin_badge_reader_path(badge_reader))}&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to('Regenerate', regenerate_api_token_admin_badge_reader_path(badge_reader), method: :post, data: { confirm: REGENERATE_API_TOKEN_WARNING })}".html_safe }
      row(:certifications) do
        certifications = badge_reader.certifications
        if certifications.empty?
          if badge_reader.restricted_access
            'None. Only the manual users listed below can badge into this reader'
          else
            'None. Any user with an active membership can badge into this reader'
          end
        else
          certifications.order(:name).map { |certification| auto_link(certification) }.join('<br/>').html_safe
        end
      end
      row(:manual_users) do
        badge_reader.manual_users.order(:name).map { |user| auto_link(user) }.join('<br/>').html_safe
      end
      row('Prevent access by the general membership', &:restricted_access)
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:description)
      f.input(:certification_ids, label: 'Certifications', as: :selected_list, url: admin_certifications_path, minimum_input_length: 0, hint: 'A user holding any of these certifications (as well as active membership) will be allowed to badge into this reader. If no certifications are specified, any user with an active membership can badge in.')
      f.input(:manual_user_ids, label: 'Manual users', as: :selected_list, url: admin_users_path, hint: 'Any user listed here can badge into this reader, whether or not they hold active membership. Good for staff members or outside instructors or volunteers. (If you need a way to add the same group of users to multiple badge readers, ask the IT team and they will add a way to make this easier, maybe user groups or something.)')
      f.input(:restricted_access, label: 'Prevent access by the general membership', hint: 'If checked, only the manual users listed above will be able to badge in. Good for staff closets and the like. If unchecked, any paid member, or any member with one of the certifications listed above, will be allowed access in addition to the listed manual users.')
    end
    f.actions
  end

  action_item :regenerate, only: :reveal_api_token do
    link_to 'Regenerate', regenerate_api_token_admin_badge_reader_path(resource), method: :post, data: { confirm: REGENERATE_API_TOKEN_WARNING }
  end

  member_action :regenerate_api_token, method: :post do
    resource.regenerate_api_token!
    flash[:notice] = "#{resource.name}'s API token has been regenerated. Please input the new API token into the badge reader; until you do, the badge reader will not work."
    redirect_to reveal_api_token_admin_badge_reader_path(resource)
  end

  member_action :reveal_api_token, method: :get do
    @page_title = "API token for #{resource.name}"
  end
end
