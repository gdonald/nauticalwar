# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout do
  subject(:layout) { create(:layout) }

  # it do
  #   is_expected.to validate_uniqueness_of(:player)
  #     .scoped_to(%i[game x y])
  #     .with_message('layout must be unique')
  # end

  let(:player_one) { build_stubbed(:player, id: 1) }
  let(:player_two) { build_stubbed(:player, id: 2) }
  let(:game_one) do
    build_stubbed(:game, id: 1, player1: player_one, player2: player_two, turn: player_one)
  end
  let(:ship_one) { build_stubbed(:ship, id: 1) }
  let(:ship_two) { build_stubbed(:ship, id: 2) }
  let(:layout_one) { build_stubbed(:layout, id: 1, game: game_one, ship: ship_one, player: player_one) }
  let(:layout_two) do
    build_stubbed(:layout, :horizontal, id: 2, game: game_one, ship: ship_two, player: player_one)
  end

  let(:player_three) { create(:player) }
  let(:player_four) { create(:player) }
  let(:ship3) { create(:ship) }
  let(:game_two) do
    create(:game, player1: player_three, player2: player_four, turn: player_three)
  end
  let(:layout3) { create(:layout, game: game_two, ship: ship3, player: player_three) }

  describe '.rand_col_row' do
    it 'returns an array of integers' do
      result = game_one.rand_col_row(9, 9)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns an array of integers between 0 and 5' do
      result = game_one.rand_col_row(5, 5)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 5)
      expect(result[1]).to be_between(0, 5)
    end
  end

  describe '.set_location' do
    it 'creates a new vertical layout' do
      expect do
        described_class.set_location(game_two, player_three, ship_one, true)
      end.to change(described_class, :count).by(1)
    end

    it 'creates a new horizontal layout' do
      expect do
        described_class.set_location(game_two, player_three, ship_one, false)
      end.to change(described_class, :count).by(1)
    end
  end

  describe '#to_s' do
    it 'returns a string' do
      expected = "Layout(player: #{player_one.name} ship: Ship(name: #{ship_one.name}, size: 2) x: 0 y: 0 vertical: true)" # rubocop:disable Layout/LineLength
      expect(layout_one.to_s).to eq(expected)
    end
  end

  describe '#vertical_hit?' do
    it 'returns true' do
      expect(layout_one).to be_vertical_hit(0, 0)
    end

    it 'returns false' do
      expect(layout_one).not_to be_vertical_hit(5, 5)
    end
  end

  describe '#horizontal_hit?' do
    it 'returns true' do
      expect(layout_two).to be_horizontal_hit(0, 0)
    end

    it 'returns false' do
      expect(layout_two).not_to be_horizontal_hit(5, 5)
    end
  end

  describe '#hit?' do
    it 'returns true' do
      expect(layout_two).to be_hit(0, 0)
    end

    it 'returns false' do
      expect(layout_two).not_to be_hit(5, 5)
    end
  end

  describe '#horizontal' do
    it 'returns true' do
      expect(layout_two.horizontal).to be_truthy
    end

    it 'returns false' do
      expect(layout_one.horizontal).to be_falsey
    end
  end

  describe '#sunk?' do
    it 'returns false' do
      expect(layout_two).not_to be_sunk
    end

    it 'returns true' do
      create(:move, player: player_three, game: game_two, layout: layout3)
      create(:move, player: player_three, game: game_two, layout: layout3, x: 1, y: 1)
      expect(layout3).to be_sunk
    end
  end
end
