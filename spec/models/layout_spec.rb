# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Layout do
  subject(:layout) { create(:layout) }

  # it do
  #   is_expected.to validate_uniqueness_of(:player)
  #     .scoped_to(%i[game x y])
  #     .with_message('layout must be unique')
  # end

  let(:player1) { build_stubbed(:player, id: 1) }
  let(:player2) { build_stubbed(:player, id: 2) }
  let(:game1) do
    build_stubbed(:game, id: 1, player1:, player2:, turn: player1)
  end
  let(:ship1) { build_stubbed(:ship, id: 1) }
  let(:ship2) { build_stubbed(:ship, id: 2) }
  let(:layout1) { build_stubbed(:layout, id: 1, game: game1, ship: ship1, player: player1) }
  let(:layout2) do
    build_stubbed(:layout, :horizontal, id: 2, game: game1, ship: ship2, player: player1)
  end

  let(:player3) { create(:player) }
  let(:player4) { create(:player) }
  let(:ship3) { create(:ship) }
  let(:game2) do
    create(:game, player1: player3, player2: player4, turn: player3)
  end
  let(:layout3) { create(:layout, game: game2, ship: ship3, player: player3) }

  describe '.rand_col_row' do
    it 'returns an array of integers' do
      result = game1.rand_col_row(9, 9)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns an array of integers between 0 and 5' do
      result = game1.rand_col_row(5, 5)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 5)
      expect(result[1]).to be_between(0, 5)
    end
  end

  describe '.set_location' do
    it 'creates a new vertical layout' do
      expect do
        described_class.set_location(game2, player3, ship1, true)
      end.to change(described_class, :count).by(1)
    end

    it 'creates a new horizontal layout' do
      expect do
        described_class.set_location(game2, player3, ship1, false)
      end.to change(described_class, :count).by(1)
    end
  end

  describe '#to_s' do
    it 'returns a string' do
      expected = "Layout(player: #{player1.name} ship: Ship(name: #{ship1.name}, size: 2) x: 0 y: 0 vertical: true)"
      expect(layout1.to_s).to eq(expected)
    end
  end

  describe '#vertical_hit?' do
    it 'returns true' do
      expect(layout1).to be_vertical_hit(0, 0)
    end

    it 'returns false' do
      expect(layout1).not_to be_vertical_hit(5, 5)
    end
  end

  describe '#horizontal_hit?' do
    it 'returns true' do
      expect(layout2).to be_horizontal_hit(0, 0)
    end

    it 'returns false' do
      expect(layout2).not_to be_horizontal_hit(5, 5)
    end
  end

  describe '#hit?' do
    it 'returns true' do
      expect(layout2).to be_hit(0, 0)
    end

    it 'returns false' do
      expect(layout2).not_to be_hit(5, 5)
    end
  end

  describe '#horizontal' do
    it 'returns true' do
      expect(layout2.horizontal).to be_truthy
    end

    it 'returns false' do
      expect(layout1.horizontal).to be_falsey
    end
  end

  describe '#sunk?' do
    it 'returns false' do
      expect(layout2).not_to be_sunk
    end

    it 'returns true' do
      create(:move, player: player3, game: game2, layout: layout3)
      create(:move, player: player3, game: game2, layout: layout3, x: 1, y: 1)
      expect(layout3).to be_sunk
    end
  end
end
