# frozen_string_literal: true

FactoryBot.define do
  factory :player do
    sequence :name do |n|
      "player#{n}"
    end
    sequence :email do |n|
      "foo#{n}@bar.com"
    end
    password 'changeme'
    password_confirmation 'changeme'
  end
end
