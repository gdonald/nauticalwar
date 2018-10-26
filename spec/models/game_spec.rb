# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game, type: :model do # rubocop:disable Metrics/BlockLength
  let(:ship) { Ship.first }
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:player_3) { create(:player) }
  let!(:game_1) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let!(:game_2) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_2)
  end

  before do
    Game.create_ships
    create(:layout, game: game_1, player: player_1, ship: ship)
    create(:layout, game: game_1, player: player_2, ship: ship, sunk: true)
  end

  describe '#random_min_col_row' do
    it 'returns indexes for least hit areas' do
      cols, rows = [[2, 2, 1], [3, 3, 2]]
      expected = [2, 2]
      expect(game_1.random_min_col_row(cols, rows)).to eq(expected)
    end
  end

  describe '#col_row_moves' do
    it 'returns empty grid' do
      expected = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
      expect(game_1.col_row_moves(player_1)).to eq(expected)
    end

    it 'returns cols and rows' do
      create(:move, game: game_1, player: player_1, x: 3, y: 3)
      expected = [[0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]]
      expect(game_1.col_row_moves(player_1)).to eq(expected)
    end
  end

  describe '#calculate_scores' do # rubocop:disable Metrics/BlockLength
    let!(:game_1) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_1)
    end
    let!(:game_2) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_2)
    end

    it 'scores a game where player 1 wins' do
      game_1.calculate_scores
      expect(player_1.wins).to eq(1)
      expect(player_1.losses).to eq(0)
      expect(player_1.rating).to eq(1216)
      expect(player_2.wins).to eq(0)
      expect(player_2.losses).to eq(1)
      expect(player_2.rating).to eq(1184)
    end

    it 'scores a game where player 2 wins' do
      game_2.calculate_scores
      expect(player_1.wins).to eq(0)
      expect(player_1.losses).to eq(1)
      expect(player_1.rating).to eq(1184)
      expect(player_2.wins).to eq(1)
      expect(player_2.losses).to eq(0)
      expect(player_2.rating).to eq(1216)
    end
  end

  describe '#calculate_scores_cancel' do # rubocop:disable Metrics/BlockLength
    let!(:game_1) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_1)
    end
    let!(:game_2) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_2)
    end

    it 'scores a canceled game where player 1 wins' do
      game_1.calculate_scores(true)
      expect(player_1.wins).to eq(1)
      expect(player_1.losses).to eq(0)
      expect(player_1.rating).to eq(1201)
      expect(player_2.wins).to eq(0)
      expect(player_2.losses).to eq(1)
      expect(player_2.rating).to eq(1199)
    end

    it 'scores a canceled game where player 2 wins' do
      game_2.calculate_scores(true)
      expect(player_1.wins).to eq(0)
      expect(player_1.losses).to eq(1)
      expect(player_1.rating).to eq(1199)
      expect(player_2.wins).to eq(1)
      expect(player_2.losses).to eq(0)
      expect(player_2.rating).to eq(1201)
    end
  end

  describe '#next_turn' do
    it 'advances to next player turn' do
      game_1.next_turn
      expect(game_1.turn).to eq(player_2)
    end
  end

  describe '#declare_winner' do
    it 'sets a game winner' do
      game_1.declare_winner
      expect(game_1.winner).to eq(player_1)
    end
  end

  describe '#all_ships_sunk?' do
    it 'returns false' do
      expect(game_1.all_ships_sunk?(player_1)).to be_falsey
    end

    it 'returns true' do
      expect(game_1.all_ships_sunk?(player_2)).to be_truthy
    end
  end

  describe '#next_player_turn' do
    it 'returns player_2' do
      expect(game_1.next_player_turn).to eq(player_2)
    end

    it 'returns player_1' do
      expect(game_2.next_player_turn).to eq(player_1)
    end
  end

  describe '#opponent' do
    it 'returns player_2' do
      expect(game_1.opponent(player_1)).to eq(player_2)
    end

    it 'returns player_1' do
      expect(game_1.opponent(player_2)).to eq(player_1)
    end
  end

  describe '.create_ships' do
    it 'creates ships' do
      expect(Ship.count).to eq(5)
    end
  end

  describe '#bot_layout' do
    it 'creates layouts' do
      expect do
        game_1.bot_layout
      end.to change(Layout, :count).by(Ship.count)
      expect(game_1.player_2_layed_out).to be_truthy
    end
  end

  describe '.find_game' do
    let(:id) { game_1.id }

    it 'returns a game for player_1' do
      expect(Game.find_game(player_1, id)).to eq(game_1)
    end

    it 'returns a game for player_2' do
      expect(Game.find_game(player_2, id)).to eq(game_1)
    end

    it 'returns nil for player_3' do
      expect(Game.find_game(player_3, id)).to be_nil
    end

    it 'returns nil for unknown game id' do
      expect(Game.find_game(player_1, 0)).to be_nil
    end
  end

  describe '#t_limit' do
    it 'returns time limit per turn in seconds' do
      travel_to game_1.updated_at do
        expect(game_1.t_limit).to eq(86_400)
      end
    end
  end

  describe '#moves_for_player' do
    let!(:move_1) { create(:move, game: game_1, player: player_1, x: 0, y: 0) }
    let!(:move_2) { create(:move, game: game_1, player: player_2, x: 0, y: 0) }

    it 'returns moves for a player' do
      expect(game_1.moves_for_player(player_1)).to eq([move_1])
    end

    it 'returns an empty array' do
      expect(game_1.moves_for_player(player_3)).to eq([])
    end
  end

  describe '#hit?' do
    let!(:layout) do
      create(:layout, game: game_1, player: player_1, ship: ship, x: 2, y: 2,
                      vertical: true)
    end

    it 'returns true' do
      expect(game_1.hit?(player_1, 2, 2)).to be_truthy
    end

    it 'returns false' do
      expect(game_1.hit?(player_2, 5, 5)).to be_falsey
    end
  end

  describe '#empty_neighbors' do # rubocop:disable Metrics/BlockLength
    let!(:layout) do
      create(:layout, game: game_1, player: player_1, ship: ship, x: 5, y: 5,
                      vertical: true)
    end
    let!(:hit) do
      create(:move, game: game_1, player: player_2, x: 5, y: 5, layout: layout)
    end

    it 'returns 4 empty neighbors for a hit' do
      expected = [[4, 6, 5, 5], [5, 5, 4, 6]]
      expect(game_1.empty_neighbors(player_2, hit)).to eq(expected)
    end

    it 'returns 3 empty neighbors for a hit' do
      create(:move, game: game_1, player: player_2, x: 5, y: 6)

      expected = [[4, 6, 5], [5, 5, 4]]
      expect(game_1.empty_neighbors(player_2, hit)).to eq(expected)
    end

    it 'returns 2 empty neighbors for a hit' do
      create(:move, game: game_1, player: player_2, x: 5, y: 6)
      create(:move, game: game_1, player: player_2, x: 5, y: 4)

      expected = [[4, 6], [5, 5]]
      expect(game_1.empty_neighbors(player_2, hit)).to eq(expected)
    end

    it 'returns 1 empty neighbor for a hit' do
      create(:move, game: game_1, player: player_2, x: 5, y: 6)
      create(:move, game: game_1, player: player_2, x: 5, y: 4)
      create(:move, game: game_1, player: player_2, x: 6, y: 5)

      expected = [[4], [5]]
      expect(game_1.empty_neighbors(player_2, hit)).to eq(expected)
    end

    it 'returns 0 empty neighborw for a hit' do
      create(:move, game: game_1, player: player_2, x: 5, y: 6)
      create(:move, game: game_1, player: player_2, x: 5, y: 4)
      create(:move, game: game_1, player: player_2, x: 6, y: 5)
      create(:move, game: game_1, player: player_2, x: 4, y: 5)

      expected = [[], []]
      expect(game_1.empty_neighbors(player_2, hit)).to eq(expected)
    end
  end
end
