# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    player1 factory: :player
    player2 factory: :player
    turn factory: :player
    time_limit { 1.day.to_i }
    rated { true }
    shots_per_turn { 1 }
  end
end
