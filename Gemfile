source "https://rubygems.org"

gem 'rails', '~> 8.1'
gem "propshaft", "~> 1.3.1"
gem "pg", "~> 1.6.3"
gem "puma", "~> 7.1.0"
gem "turbo-rails", "~> 2.0.16"
gem "stimulus-rails", "~> 1.3.4"
gem "jbuilder", "~> 2.14.1"
gem "devise", "~> 5.0.2"
gem "omniauth", "~> 2.1.3"
gem "omniauth-google-oauth2", "~> 1.2.2"
gem "omniauth-linkedin-oauth2", "~> 1.0.1"
gem "omniauth-facebook", "~> 10.0.0"
gem "omniauth-twitter2", "~> 1.0.0"
gem "omniauth-rails_csrf_protection", "~> 2.0.1"
gem "image_processing", "~> 1.14.0"
gem "mini_magick", "~> 5.3.1"
gem "streamio-ffmpeg", "~> 3.0.2"
gem "jsbundling-rails", "~> 1.3.1"
gem "cssbundling-rails", "~> 1.4.3"
gem "mail", "~> 2.9.0"
gem "view_component", "~> 4.2.0"
gem "aws-sdk-s3", "~> 1.211.0", require: false
gem "dry-initializer", "~> 3.2.0"
gem "mission_control-jobs", "~> 1.1.0"
gem "pagy", "~> 9.0"
gem "avo", "~> 3.28.0"
gem 'openssl', '~> 4.0'
gem 'ruby_llm', '~> 1.12'
gem "ransack", "~> 4.4.1"
gem "redcarpet", "~> 3.6.1"
gem "coderay", "~> 1.1.3"
gem "resend", "~> 1.0.0"

# Payment Processing
gem "pay", "~> 11.3"
gem "stripe", "~> 18"
gem "receipts", "~> 2.4"

gem "tzinfo-data", "~> 1.2025.1", platforms: %i[ windows jruby ]

gem "solid_cache", "~> 1.0.10"
gem "solid_queue", "~> 1.3.2"
gem "solid_cable", "~> 3.0.11"

gem "bootsnap", "~> 1.21.1", require: false
gem "kamal", "~> 2.10.1", require: false
gem "thruster", "~> 0.1.17", require: false

# Development & Test Gems
group :development, :test do
  gem "debug", "~> 1.11.1", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", "~> 7.1.2", require: false
  gem "rubocop-rails-omakase", "~> 1.1.0", require: false
end

group :development do
  gem "web-console", "~> 4.3.0"
  gem "hotwire-spark", "~> 0.1.13"
  gem "letter_opener", "~> 1.10.0"
  gem "letter_opener_web", "~> 3.0.0"
  gem "pry", "~> 0.16.0"
  gem "pry-remote", "~> 0.1.8"
  gem "better_errors", "~> 2.10.1"
  gem "binding_of_caller", "~> 1.0.1"
end

group :test do
  gem "capybara", "~> 3.40.0"
  gem "selenium-webdriver", "~> 4.41.0"
end
