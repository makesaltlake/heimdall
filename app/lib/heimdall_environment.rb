module HeimdallEnvironment
  def self.environment
    ENV['HEIMDALL_ENV'] || 'local'
  end
end
