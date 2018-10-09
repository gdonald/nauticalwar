# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# ruby '2.3.4'

gem 'rails', '~> 5.2.0'
# gem 'pg', '>= 0.18', '< 2.0'
gem 'pg', '= 0.21.0'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
# gem 'mini_racer', platforms: :ruby
gem 'bcrypt', '~> 3.1.7'
gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'

gem 'active_model_serializers'
gem 'activerecord-session_store'
gem 'acts_as_list'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'devise'
gem 'factory_bot_rails'
gem 'figaro'
gem 'haml-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
# gem 'omniauth'
# gem 'omniauth-facebook'
# gem 'omniauth-google-oauth2'
gem 'paperclip'
# gem 'simple_form'
# gem 'thor', '0.19.1'
gem 'tzinfo-data'
gem 'will_paginate-bootstrap'

gem 'bootsnap', '>= 1.1.0', require: false

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'faker'
  gem 'pry'
  gem 'rspec-rails'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'capybara-webkit'
  gem 'chromedriver-helper'
  gem 'database_cleaner'
  gem 'selenium-webdriver'
end

gem 'simplecov', require: false, group: :test
