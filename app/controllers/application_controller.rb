class ApplicationController < ActionController::Base
  def admin_access_denied(exception)
    # TODO: pretty this up, maybe tell them to email MSL for help
    render plain: "Sorry, you're not allowed to do that: #{exception.message}", status: :forbidden
  end
end
