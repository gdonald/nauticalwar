# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    association :user_1
    association :user_2
    association :turn
    time_limit { 1.day.to_i }
    rated true
    five_shot true
  end
end
