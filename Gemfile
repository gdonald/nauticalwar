# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'bcrypt', '~> 3.1.7'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'coffee-rails', '~> 4.2'
gem 'pg'
gem 'puma'
gem 'rails', '= 5.2.2'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'

gem 'active_model_serializers'
gem 'activeadmin'
gem 'activerecord-session_store'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'factory_bot_rails'
gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'tzinfo-data'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'faker'
  gem 'pry'
  gem 'rspec-rails'
  gem 'wirble'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara-selenium'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
  gem 'webdrivers'
end
