# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '= 5.2.1'
gem 'pg'
gem 'puma'
gem 'sass-rails', '~> 5.0'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'uglifier', '>= 1.3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'

gem 'active_model_serializers'
gem 'activeadmin'
gem 'activerecord-session_store'
gem 'acts_as_list'
gem 'devise'
gem 'factory_bot_rails'
gem 'figaro'
gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'paperclip'
gem 'tzinfo-data'
gem 'bootsnap', '>= 1.1.0', require: false

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
  gem 'chromedriver-helper'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
end

gem 'simplecov', require: false, group: :test
