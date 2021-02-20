source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3'
# Use Postrges as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'devise'
gem 'paper_trail'
gem 'activeadmin'
gem 'cancancan'
gem 'activeadmin_addons'
# because select2-rails, which activeadmin_addons requires, pins a super old
# version of thor
gem 'thor', '0.20.3'
gem 'faker' # yes, in production too - that lets us seed data into demo environments
gem 'paint'
gem 'inst-jobs'
gem 'stripe'
gem 'sentry-raven'
gem 'after_transaction_commit'
gem 'slack-ruby-client'
gem 'nilify_blanks'
gem 'aws-sdk-s3', require: false
gem 'mini_magick' # for active storage
gem 'image_processing' # for active storage
gem 'faraday'

group :development do
  # Work around https://github.com/ctran/annotate_models/issues/761 -
  # https://github.com/ctran/annotate_models/pull/803 has been merged but not
  # released yet, so target master until that happens. The git stuff can go
  # away at that point.
  gem 'annotate', git: 'https://github.com/ctran/annotate_models.git'
end

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'selenium-webdriver'
end
