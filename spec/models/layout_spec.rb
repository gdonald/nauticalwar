# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout, type: :model do
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:game) { create(:game, player_1: player_1, player_2: player_2, turn: player_1) }
  let(:ship_1) { create(:ship) }
  let(:ship_2) { create(:ship) }
  let(:layout_1) { create(:layout, game: game, ship: ship_1, player: player_1) }
  let(:layout_2) { create(:layout, :horizontal, game: game, ship: ship_2, player: player_1) }

  describe '#to_s' do
    it 'returns a string' do
      expected = "Layout(player: #{player_1.name} ship: Ship(name: #{ship_1.name}, size: 2) x: 0 y: 0 vertical: true)"
      expect(layout_1.to_s).to eq(expected)
    end
  end

  describe '#vertical_hit?' do
    it 'returns true' do
      expect(layout_1.vertical_hit?(0, 0)).to be_truthy
    end

    it 'returns false' do
      expect(layout_1.vertical_hit?(5, 5)).to be_falsey
    end
  end

  describe '#horizontal_hit?' do
    it 'returns true' do
      expect(layout_2.horizontal_hit?(0, 0)).to be_truthy
    end

    it 'returns false' do
      expect(layout_2.horizontal_hit?(5, 5)).to be_falsey
    end
  end

  describe '#hit?' do
    it 'returns true' do
      expect(layout_2.hit?(0, 0)).to be_truthy
    end

    it 'returns false' do
      expect(layout_2.hit?(5, 5)).to be_falsey
    end
  end

  describe '#horizontal' do
    it 'returns true' do
      expect(layout_2.horizontal).to be_truthy
    end

    it 'returns false' do
      expect(layout_1.horizontal).to be_falsey
    end
  end
end
