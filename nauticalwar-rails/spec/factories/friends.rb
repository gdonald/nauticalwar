# frozen_string_literal: true

FactoryBot.define do
  factory :friend do
    player1 factory: :player
    player2 factory: :player
  end
end
