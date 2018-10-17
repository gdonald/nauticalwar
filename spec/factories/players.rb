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
    last_sign_in_at Time.current
        
    trait :bot do
      bot true
    end
  end
end
