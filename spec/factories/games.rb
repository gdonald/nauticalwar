# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    association :player_1
    association :player_2
    association :turn
    time_limit { 1.day.to_i }
    rated { true }
    shots_per_turn { 1 }
  end
end
