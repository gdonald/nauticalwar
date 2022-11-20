# frozen_string_literal: true

FactoryBot.define do
  factory :friend do
    player1 { create(:player) }
    player2 { create(:player) }
  end
end
