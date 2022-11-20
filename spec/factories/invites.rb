# frozen_string_literal: true

FactoryBot.define do
  factory :invite do
    association :player1
    association :player2
    time_limit { 1.day.to_i }
    rated { true }
    shots_per_turn { 1 }
  end
end
