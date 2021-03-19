# Fix for https://github.com/rails/rails/pull/41700 - this file can be deleted as soon as that pull request is merged
# and Heimdall's version of ActionCable bumped to whatever release that PR makes it into.

class ActionCable::RemoteConnections::RemoteConnection
  def disconnect
    server.broadcast internal_channel, { type: "disconnect" }
  end
end
