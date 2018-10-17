# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout, type: :model do
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:game) { create(:game, player_1: player_1, player_2: player_2, turn: player_1) }
  let(:ship) { create(:ship) }
  let(:layout) { create(:layout, game: game, ship: ship, player: player_1) }

  describe '#to_s' do
    it 'returns a string' do
      expected = "Layout(player: #{player_1.name} ship: Ship(name: #{ship.name}, size: 2) x: 0 y: 0 vertical: true)"
      expect(layout.to_s).to eq(expected)
    end
  end
end
