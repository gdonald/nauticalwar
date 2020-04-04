# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout, type: :model do # rubocop:disable Metrics/BlockLength
  let(:player_1) { build_stubbed(:player, id: 1) }
  let(:player_2) { build_stubbed(:player, id: 2) }
  let(:game_1) do
    build_stubbed(:game, id: 1, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let(:ship_1) { build_stubbed(:ship, id: 1) }
  let(:ship_2) { build_stubbed(:ship, id: 2) }
  let(:layout_1) { build_stubbed(:layout, id: 1, game: game_1, ship: ship_1, player: player_1) }
  let(:layout_2) do
    build_stubbed(:layout, :horizontal, id: 2, game: game_1, ship: ship_2, player: player_1)
  end

  let(:player_3) { create(:player) }
  let(:player_4) { create(:player) }
  let(:ship_3) { create(:ship) }
  let(:game_2) do
    create(:game, player_1: player_3, player_2: player_4, turn: player_3)
  end
  let(:layout_3) { create(:layout, game: game_2, ship: ship_3, player: player_3) }

  describe '.rand_col_row' do
    it 'returns an array of integers' do
      result = game_1.rand_col_row(9, 9)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns an array of integers between 0 and 5' do
      result = game_1.rand_col_row(5, 5)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 5)
      expect(result[1]).to be_between(0, 5)
    end
  end

  describe '.set_location' do
    it 'creates a new vertical layout' do
      expect do
        Layout.set_location(game_2, player_3, ship_1, true)
      end.to change(Layout, :count).by(1)
    end

    it 'creates a new horizontal layout' do
      expect do
        Layout.set_location(game_2, player_3, ship_1, false)
      end.to change(Layout, :count).by(1)
    end
  end

  describe '#to_s' do
    it 'returns a string' do
      expected = "Layout(player: #{player_1.name} ship: Ship(name: #{ship_1.name}, size: 2) x: 0 y: 0 vertical: true)" # rubocop:disable Layout/LineLength
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
      expect(layout_2.sunk?).to be_falsey
    end

    it 'returns true' do
      create(:move, player: player_3, game: game_2, layout: layout_3)
      create(:move, player: player_3, game: game_2, layout: layout_3, x: 1, y: 1)
      expect(layout_3.sunk?).to be_truthy
    end
  end
end
