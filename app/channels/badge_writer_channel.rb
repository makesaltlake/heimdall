class BadgeWriterChannel < ApplicationCable::Channel
  def subscribed
    return reject unless client_resource.is_a?(BadgeWriter)

    stream_for client_resource
  end
end
