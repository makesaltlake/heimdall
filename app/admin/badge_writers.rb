ActiveAdmin.register BadgeWriter do
  REGENERATE_BADGE_WRITER_API_TOKEN_WARNING = "WARNING: Regenerating a badge writer's API token will cause it to stop working until the new API token has been entered in. Are you sure you want to regenerate this badge writer's API token?"

  menu parent: 'Badges', priority: 2

  config.sort_order = 'name_asc'

  permit_params :name, :description

  filter :name

  index do
    column(:name) { |badge_writer| auto_link(badge_writer) }
    column(:description)
  end

  show do
    attributes_table do
      row(:name)
      row(:description) { |badge_writer| format_multi_line_text(badge_writer.description) }
      row(:api_token) { |badge_writer| "#{link_to('Reveal', reveal_api_token_admin_badge_writer_path(badge_writer))}&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;#{link_to('Regenerate', regenerate_api_token_admin_badge_writer_path(badge_writer), method: :post, data: { confirm: REGENERATE_BADGE_WRITER_API_TOKEN_WARNING })}".html_safe }
    end
  end

  form do |f|
    f.inputs do
      f.input(:name)
      f.input(:description)
    end
    f.actions
  end

  action_item :regenerate, only: :reveal_api_token do
    link_to 'Regenerate', regenerate_api_token_admin_badge_writer_path(resource), method: :post, data: { confirm: REGENERATE_BADGE_WRITER_API_TOKEN_WARNING }
  end

  member_action :regenerate_api_token, method: :post do
    resource.regenerate_api_token!
    flash[:notice] = "#{resource.name}'s API token has been regenerated. Please input the new API token into the badge writer; until you do, the badge writer will not work."
    redirect_to reveal_api_token_admin_badge_writer_path(resource)
  end

  member_action :reveal_api_token, method: :get do
    @page_title = "API token for #{resource.name}"
  end
end
