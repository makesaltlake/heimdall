module HeimdallEnvironment
  def self.environment
    ENV['HEIMDALL_ENV'] || 'local'
  end

  def self.staging?
    environment == 'staging'
  end

  def self.production?
    environment == 'production'
  end

  def self.staging_or_production?
    staging? || production?
  end
end
