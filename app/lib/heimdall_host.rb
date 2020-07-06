module HeimdallHost
  def self.host
    ENV['HEIMDALL_HOST']
  end

  # Takes a path (like '/admin/users/123') and turns it into a fullly-qualified
  # URL (like 'https://heimdall.example.com/admin/users/123') pointing at this
  # Heimdall instance using the HEIMDALL_HOST environment variable. If
  # HEIMDALL_HOST is not specified, nil is returned instead.
  def self.full_url(path)
    URI.join("https://#{host}", path) if host
  end
end
