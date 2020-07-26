# Superclass of all controllers that service API routes.
#
# This class provides helpers to deal with authenticating API endpoints based
# on a particular model. It can be used like this:
#
# class Api::SomeController
#   authenticate_using SomeModel
#
#   def some_route
#     # ...
#     render plain: "You're currently accessing this controller as #{resource}"
#   end
# end
#
# Internally Api::ApiController will add a before filter that:
#
#   - checks that the request has an `Authorization` header whose value is of
#     the form `Bearer <token>`
#   - calls `.find(api_token: <token>)` on the model passed to
#     `authenticate_using`
#   - makes the resulting model available via `resource`, and
#   - prevents the request from happening if no such model exists or if an
#     authorization token was not provided.
#
# Api::ApiController also takes care of augmenting the metadata tacked on to
# any PaperTrail::Versions created by modifications made by the request with
# the resource that made the modifications; in the above example, a modification
# to a model that `has_paper_trail` would result in a PaperTrail::Version with
# `metadata` that looks like:
#
# {
#   "api_resource": {
#     "type": "SomeModel",
#     "id": 123
#   }
# }
#
# (In the future, it would be nice to add a polymorphic alternative to paper
# trail's `whodunnit` column and store the resource in that association.)
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

    # Note: similar logic is duplicated in ApplicationController to handle
    # authentication of websocket requests on behalf of badge readers; we
    # should unify that piece and this one at some point, perhaps into an
    # `authenticate_via_api_token(<token>)` method on each authenticable
    # model.
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
