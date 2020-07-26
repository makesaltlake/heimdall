class BadgeReaderChannel < ApplicationCable::Channel
  def subscribed
    return reject unless client_resource.is_a?(BadgeReader)

    stream_for client_resource
  end

  def report_manually_opened
    return reject unless client_resource.is_a?(BadgeReader)

    client_resource.report_manually_opened!
  end
end
