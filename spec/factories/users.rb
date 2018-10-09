# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :username do |n|
      "user#{n}"
    end
    sequence :email do |n|
      "foo#{n}@bar.com"
    end
    password 'changeme'
    password_confirmation 'changeme'
  end
end
