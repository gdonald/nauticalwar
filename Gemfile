# frozen_string_literal: true

ruby '3.1.2'

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'bcrypt', '~> 3.1.7'
gem 'bootstrap-sass', '>= 3.4.1'
gem 'coffee-rails'
gem 'pg'
gem 'rails'
gem 'sass-rails'
gem 'uglifier'

gem 'activeadmin'
gem 'active_model_serializers'
gem 'activerecord-session_store'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'factory_bot_rails'
gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'tzinfo-data'

gem 'ed25519'
gem 'bcrypt_pbkdf'

# Until Ruby 3
gem 'strscan', '1.0.3'

gem 'net-smtp', require: false

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'faker'
  gem 'pry'
  gem 'rspec-rails'
  gem 'rubocop-rails', require: false
  gem 'ruby-prof', '>= 0.17.0', require: false
  gem 'stackprof', '>= 0.2.9', require: false
  gem 'wirble'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'listen'
  gem 'puma'
  gem 'web-console'
end

group :test do
  gem 'capybara', '>= 3.20.2'
  gem 'capybara-selenium'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
  gem 'test-prof'
  gem 'webdrivers'
end
