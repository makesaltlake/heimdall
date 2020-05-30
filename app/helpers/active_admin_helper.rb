module ActiveAdminHelper
  def format_multi_line_text(text)
    CGI.escapeHTML(text || '').split("\n").map(&:chomp).join("<br/>").html_safe
  end

  def paper_trail_version_author(version, show_unknown: false)
    if version.whodunnit && user = User.find_by(id: version.whodunnit)
      auto_link(user)
    elsif version.whodunnit
      "User ##{version.whodunnit}"
    elsif delayed_job_tag = version.metadata&.[]('delayed_job')&.[]('tag')
      "Background task: #{delayed_job_tag}"
    elsif api_resource = version.metadata&.[]('api_resource')
      if resource = api_resource['type'].constantize.find_by(id: api_resource['id'])
        auto_link(resource)
      else
        "#{api_resource['type']} ##{api_resource['id']}"
      end
    elsif version.metadata&.[]('controller') == 'active_admin/devise/sessions' && version.metadata&.[]('action') == 'create'
      'login screen'
    else
      '<span class="empty">unknown</span>'.html_safe if show_unknown
    end
  end
end
