# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'bcrypt', '~> 3.1.7'
gem 'bootstrap-sass', '>= 3.4.1'
gem 'coffee-rails'
gem 'pg'
gem 'puma'
gem 'rails'
gem 'sass-rails'
gem 'uglifier'

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


  # TODO: remove this:
  %w[rspec-core rspec-expectations rspec-mocks rspec-rails rspec-support].each do |lib|
    gem lib, git: "https://github.com/rspec/#{lib}.git", branch: 'master'
  end

  # TODO: add this back:
  # gem 'rspec-rails'


  gem 'wirble'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console'
end

group :test do
  gem 'capybara-selenium'
  gem 'database_cleaner'
  gem 'rspec_junit_formatter'
  gem 'rails-controller-testing'
  gem 'simplecov', require: false
  gem 'webdrivers'
end
