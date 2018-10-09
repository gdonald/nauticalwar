# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }
  let(:user_3) { create(:user) }

  describe '.find_game' do
    let!(:game) { create(:game, user_1: user_1, user_2: user_2, turn: user_1) }
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
    let!(:game) { create(:game, user_1: user_1, user_2: user_2, turn: user_1) }

    it 'returns time limit per turn in seconds' do
      travel_to game.updated_at do
        expect(game.t_limit).to eq(86_400)
      end
    end
  end
end
