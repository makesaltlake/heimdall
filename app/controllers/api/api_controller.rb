class Api::ApiController < ApplicationController
  # prepend this one so that it happens before ApplicationController's
  # set_paper_trail_whodunnit; otherwise we won't have loaded @resource when
  # info_for_paper_trail is called
  prepend_before_action :authenticate_api_request
  skip_before_action :verify_authenticity_token

  class_attribute :authentication_model_class
  attr_reader :resource

  # call this in a subclass to specify what model should be used to
  # authenticate the caller
  def self.authenticate_using(authentication_model_class)
    self.authentication_model_class = authentication_model_class
  end

  private def authenticate_api_request
    return render plain: 'Forbidden', status: :forbidden unless authentication_model_class

    authorization_header = request.headers['Authorization']
    api_token = authorization_header&.match(/^Bearer (.+)$/)&.captures&.first
    return render plain: 'Forbidden', status: :forbidden unless api_token

    resource = authentication_model_class.find_by(api_token: api_token)
    return render plain: 'Forbidden', status: :forbidden unless resource

    @resource = resource
  end

  def info_for_paper_trail
    super.deep_merge({
      metadata: {
        api_resource: @resource && {
          type: resource.class.name,
          id: resource.id
        }
      }
    })
  end
end
