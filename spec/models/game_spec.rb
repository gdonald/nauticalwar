# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:user_3) { create(:user) }
  let!(:game) { create(:game, user_1: user_1, user_2: user_2, turn: user_1) }

  describe '.find_game' do
    let(:id) { game.id }

    it 'returns a game for user_1' do
      expect(Game.find_game(user_1, id)).to eq(game)
    end

    it 'returns a game for user_2' do
      expect(Game.find_game(user_2, id)).to eq(game)
    end

    it 'returns nil for user_3' do
      expect(Game.find_game(user_3, id)).to be_nil
    end

    it 'returns nil for unknown game id' do
      expect(Game.find_game(user_1, 0)).to be_nil
    end
  end

  describe '#t_limit' do
    it 'returns time limit per turn in seconds' do
      travel_to game.updated_at do
        expect(game.t_limit).to eq(86_400)
      end
    end
  end

  describe '#moves_for_user' do
    let!(:move_1) { create(:move, game: game, user: user_1, x: 0, y: 0) }
    let!(:move_2) { create(:move, game: game, user: user_2, x: 0, y: 0) }

    it 'returns moves for a user' do
      expect(game.moves_for_user(user_1)).to eq([move_1])
    end

    it 'returns an empty array' do
      expect(game.moves_for_user(user_3)).to eq([])
    end
  end

  describe '#is_hit?' do
    let(:ship) { create(:ship) }
    let!(:layout) { create(:layout, game: game, user: user_1, ship: ship, x: 0, y: 0, vertical: true) }

    it 'returns true' do
      expect(game.is_hit?(user_1, 0, 0)).to be_truthy
    end

    it 'returns false' do
      expect(game.is_hit?(user_2, 1, 1)).to be_falsey
    end
  end

  describe '#empty_neighbors' do
    let(:ship) { create(:ship) }
    let!(:layout) { create(:layout, game: game, user: user_1, ship: ship, x: 0, y: 0, vertical: true) }
    let!(:hit) { create(:move, game: game, user: user_2, x: 0, y: 0, layout: layout) }

    it 'returns empty neighbors for a hit' do
      expected = [[1, 0], [0, 1]]
      expect(game.empty_neighbors(user_1, hit)).to eq(expected)
    end
  end
end
