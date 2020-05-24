class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit

  def info_for_paper_trail
    {
      metadata: {
        controller: controller_path,
        action: action_name
        # TODO: add request.remote_ip here, but first validate that the way Rails
        # parses the X-Forwarded-For header from Heroku is not vulnerable to
        # spoofing attacks
      }
    }
  end

  def admin_access_denied(exception)
    # TODO: pretty this up, maybe tell them to email MSL for help
    render plain: "Sorry, you're not allowed to do that: #{exception.message}", status: :forbidden
  end
end
