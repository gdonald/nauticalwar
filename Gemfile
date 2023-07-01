# frozen_string_literal: true

ruby '3.2.1'

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'activeadmin', '~> 2.14.0'
gem 'active_model_serializers', '~> 0.10.13'
gem 'bcrypt', '~> 3.1.18'
gem 'bcrypt_pbkdf', '~> 1.1.0'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'coffee-rails', '~> 5.0.0'
gem 'ed25519', '~> 1.3.0'
gem 'factory_bot_rails', '~> 6.2.0'
gem 'haml-rails', '~> 2.1.0'
gem 'jquery-rails', '~> 4.6.0'
gem 'jquery-ui-rails', '~> 6.0.1'
gem 'net-smtp', '~> 0.3.3', require: false
gem 'pg', '~> 1.5.3'
gem 'rails', '~> 7.0.4'
gem 'sass-rails', '~> 6.0.0'
gem 'uglifier', '~> 4.2.0'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'faker'
  gem 'pry'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'ruby-prof', require: false
  gem 'stackprof', require: false
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
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'test-prof'
  gem 'webdrivers'
end
