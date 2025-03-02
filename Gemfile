source "https://rubygems.org"


gem "rails", "~> 8.0.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "devise"
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-facebook'
gem 'omniauth-twitter2'
gem 'omniauth-rails_csrf_protection' # Required for security
gem "image_processing"
gem "mini_magick"
gem "streamio-ffmpeg"
gem "jsbundling-rails"
gem "cssbundling-rails"
gem "mail"
gem "aws-sdk-s3", require: false

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false

gem "kamal", require: false

gem "thruster", require: false

# Payment processing
gem "pay", "~> 8.3.0"
gem "stripe", "~> 13.0"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
  gem "hotwire-spark"
  gem "letter_opener"
  gem "letter_opener_web"
  gem "pry"
  gem "pry-remote"
  gem "better_errors"
  gem "binding_of_caller"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem "view_component", "~> 3.21"

gem "langchainrb", "~> 0.19.4"

gem "ruby-openai", "~> 7.4"

gem "dry-initializer", "~> 3.2"
