module ApplicationCable
  class Connection < ActionCable::Connection::Base
    CLIENT_TYPES = ['badge_reader']

    identified_by :client_resource

    def connect
      client_type = request.params[:type]
      reject_unauthorized_connection unless CLIENT_TYPES.include?(client_type)

      send("authenticate_as_#{client_type}")
    end

    def authenticate_as_badge_reader
      token = request.params[:token]
      reject_unauthorized_connection unless token.presence

      resource = BadgeReader.find_by(api_token: token)
      reject_unauthorized_connection unless resource

      self.client_resource = resource
    end
  end
end
