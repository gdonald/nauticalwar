# frozen_string_literal: true

FactoryBot.define do
  factory :enemy do
    player1 { create(:player) }
    player2 { create(:player) }
  end
end
