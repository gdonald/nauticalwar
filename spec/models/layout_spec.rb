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

  describe '.sample_col_row' do
    it 'returns an array of integers' do
      result = Layout.sample_col_row(9, 9)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns an array of integers between 0 and 5' do
      result = Layout.sample_col_row(5, 5)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 5)
      expect(result[1]).to be_between(0, 5)
    end
  end

  describe '.set_location' do
    it 'creates a new vertical layout' do
      expect do
        Layout.set_location(game, player_1, ship_1, true)
      end.to change(Layout, :count).by(1)
    end

    it 'creates a new horizontal layout' do
      expect do
        Layout.set_location(game, player_1, ship_1, false)
      end.to change(Layout, :count).by(1)
    end
  end

  describe '.vertical_location' do
    it 'returns a row and col' do
      result = Layout.vertical_location(game, player_1, ship_1)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end
  end

  describe '.horizontal_location' do
    it 'returns a row and col' do
      result = Layout.horizontal_location(game, player_1, ship_1)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end
  end

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

  describe '#sunk?' do
    it 'returns false' do
      expect(layout_1.sunk?).to be_falsey
    end

    it 'returns true' do
      create(:move, player: player_1, game: game, layout: layout_1)
      create(:move, player: player_1, game: game, layout: layout_1, x: 1, y: 1)
      expect(layout_1.sunk?).to be_truthy
    end
  end
end
