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
      row(:currently_programming_a_badge_for) do |badge_writer|
        if badge_writer.programming?
          text_node auto_link(badge_writer.currently_programming_user)
          text_node "&nbsp;&nbsp;".html_safe
          text_node "(#{distance_of_time_in_words(Time.now, badge_writer.currently_programming_user_until, include_seconds: true)} left to program. "
          text_node link_to('Cancel', cancel_programming_admin_badge_writer_path(badge_writer), method: :post)
          text_node ')'
        elsif badge_writer.last_programmed_user
          "No-one, but this badge writer was used to program a badge for #{auto_link(badge_writer.last_programmed_user)} #{distance_of_time_in_words(badge_writer.last_programmed_at, Time.now, include_seconds: true)} ago".html_safe
        else
          nil # TODO: show the most recently programmed user for convenience
        end
      end
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

  collection_action :set_currently_programming_user, method: :post do
    badge_writer = BadgeWriter.find(params[:badge_writer][:id])
    authorize_resource! badge_writer

    user = User.find(params[:badge_writer][:currently_programming_user_id])

    badge_writer.set_currently_programming_user!(user)

    flash[:notice] = "Great - now tap the new badge against this badge writer to program it for #{user.name}."
    redirect_to resource_path(badge_writer)
  end

  member_action :cancel_programming, method: :post do
    resource.cancel_programming!
    flash[:notice] = "Programming has been cancelled."
    redirect_to resource_path(resource)
  end
end
