# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    username 'username'
    email 'foo@bar.com'
    password 'changeme'
    password_confirmation 'changeme'
  end
end
