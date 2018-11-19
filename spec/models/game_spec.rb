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
  end

  describe '#bot_attack_1!' do # rubocop:disable Metrics/BlockLength
    let(:bot) { create(:player, :bot, strength: 3) }
    let!(:game) do
      create(:game, player_1: player_1, player_2: bot, turn: player_1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game: game, player: player_1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let!(:move) do
        create(:move, game: game, player: bot, x: 3, y: 5, layout: layout)
      end

      it 'creates 1 bot move' do
        expect do
          game.bot_attack_1!
        end.to change(Move, :count).by(1)
      end
    end

    describe 'with a non-sinking ship' do
      let!(:layout) do
        create(:layout, game: game, player: player_1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      it 'creates 1 bot move' do
        expect do
          game.bot_attack_1!
        end.to change(Move, :count).by(1)
      end
    end
  end

  describe '#bot_attack_5!' do # rubocop:disable Metrics/BlockLength
    let(:bot) { create(:player, :bot, strength: 3) }
    let!(:game) do
      create(:game, player_1: player_1, player_2: bot, turn: player_1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game: game, player: player_1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let!(:move) do
        create(:move, game: game, player: bot, x: 3, y: 5, layout: layout)
      end

      it 'creates 5 bot moves' do
        expect do
          game.bot_attack_5!
        end.to change(Move, :count).by(5)
      end
    end

    describe 'with a non-sinking ship' do
      let!(:layout) do
        create(:layout, game: game, player: player_1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      it 'creates 5 bot moves' do
        expect do
          game.bot_attack_5!
        end.to change(Move, :count).by(5)
      end
    end
  end

  describe '#move_exists?' do
    it 'returns false' do
      expect(game_1.move_exists?(player_1, 0, 0)).to be_falsey
    end

    describe 'when there is a move' do
      let(:layout) do
        create(:layout, game: game_1, player: player_1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let!(:move) do
        create(:move, game: game_1, player: player_2, x: 3, y: 5,
                      layout: layout)
      end

      it 'returns true' do
        expect(game_1.move_exists?(player_2, 3, 5)).to be_truthy
      end
    end
  end

  describe '#create_ship_layout' do
    it 'creates ship layout' do
      hash = { 'name' => 'Carrier', 'x' => 1, 'y' => 1, 'vertical' => 1 }
      expect do
        game_1.create_ship_layout(player_1, hash)
      end.to change(Layout, :count).by(1)
    end
  end

  describe '#create_ship_layouts' do
    it 'creates ship layouts' do
      layout = { ships: [
        { name: 'Carrier', x: 1, y: 1, vertical: 1 },
        { name: 'Battleship',  x: 2, y: 7, vertical: 0 },
        { name: 'Destroyer',   x: 5, y: 3, vertical: 1 },
        { name: 'Submarine',   x: 7, y: 6, vertical: 1 },
        { name: 'Patrol Boat', x: 6, y: 1, vertical: 0 }
      ] }.to_json
      params = { game_id: game_1.id, layout: layout }
      expect do
        game_1.create_ship_layouts(player_1, params)
      end.to change(Layout, :count).by(5)
      expect(game_1.player_1_layed_out).to be_truthy
    end
  end

  describe '#vertical_location' do
    it 'returns a row and col' do
      result = game_1.vertical_location(player_1, ship)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end
  end

  describe '#horizontal_location' do
    it 'returns a row and col' do
      result = game_1.horizontal_location(player_1, ship)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end
  end

  describe '#attack_known_vert' do
    it 'creates and returns a move on a vertical layout' do
      layout = create(:layout, game: game_1, player: player_2, ship: Ship.last,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      create(:move, game: game_1, player: player_1, x: 3, y: 6, layout: layout)
      expect do
        game_1.attack_known_vert(player_1, player_2, layout.moves)
      end.to change(Move, :count).by(1)
    end

    it 'creates and returns a move on a horizontal layout' do
      layout = create(:layout, game: game_1, player: player_2, ship: Ship.last,
                               x: 3, y: 5)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      create(:move, game: game_1, player: player_1, x: 4, y: 5, layout: layout)
      expect do
        game_1.attack_known_vert(player_1, player_2, layout.moves)
      end.to change(Move, :count).by(1)
    end
  end

  describe '#attack_vertical' do
    it 'returns possible vertical moves' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      result = game_1.attack_vertical(player_1, layout.moves)
      expect(result).to eq([[3, 3], [4, 6]])
    end
  end

  describe '#attack_horizontal' do
    it 'returns possible horizontal moves' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: false)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      result = game_1.attack_horizontal(player_1, layout.moves)
      expect(result).to eq([[2, 4], [5, 5]])
    end
  end

  describe '#attack_unknown_vert' do
    it 'creates a move and returns true' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      hit = create(:move, game: game_1, player: player_1, x: 3, y: 5,
                          layout: layout)
      create(:move, game: game_1, player: player_1, x: 3, y: 6, layout: layout)
      create(:move, game: game_1, player: player_1, x: 4, y: 5)
      create(:move, game: game_1, player: player_1, x: 2, y: 5)
      expect(game_1.attack_unknown_vert(player_1, player_2, hit)).to be_truthy
      move = game_1.moves.last
      expect(move.x).to eq(3)
      expect(move.y).to eq(4)
    end

    it 'returns false' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      hit = create(:move, game: game_1, player: player_1, x: 3, y: 5,
                          layout: layout)
      create(:move, game: game_1, player: player_1, x: 3, y: 6, layout: layout)
      create(:move, game: game_1, player: player_1, x: 4, y: 5)
      create(:move, game: game_1, player: player_1, x: 2, y: 5)
      create(:move, game: game_1, player: player_1, x: 3, y: 4)
      expect(game_1.attack_unknown_vert(player_1, player_2, hit)).to be_falsey
    end
  end

  describe '#normal_range' do
    it 'returns a range from 0 to 9' do
      expect(game_1.normal_range(-1, 10)).to eq((0..9))
    end

    it 'returns a range from 2 to 7' do
      expect(game_1.normal_range(2, 7)).to eq((2..7))
    end
  end

  describe '#attack_sinking_ship' do
    it 'returns nil' do
      result = game_1.attack_sinking_ship(player_1, player_2)
      expect(result).to_not be
    end

    it 'calls attack_known_vert' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      create(:move, game: game_1, player: player_1, x: 3, y: 6, layout: layout)
      moves = layout.moves
      expect(game_1).to receive(:attack_known_vert).with(player_1, player_2,
                                                         moves)
      game_1.attack_sinking_ship(player_1, player_2)
    end

    it 'calls attack_unknown_vert' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      moves = layout.moves
      expect(game_1).to receive(:attack_unknown_vert).with(player_1, player_2,
                                                           moves.first)
      game_1.attack_sinking_ship(player_1, player_2)
    end
  end

  describe '#attack_random_ship' do
    it 'attacks a random ship' do
      expect do
        game_1.attack_random_ship(player_1, player_2)
      end.to change(Move, :count).by(1)
    end

    it 'attacks a random ship using get_random_move_spacing' do
      layout = double('layout')
      allow(layout).to receive(:nil?).once.and_return(true)
      allow(game_1).to receive(:again?).with(player_1) { true }
      expect(game_1).to receive(:get_random_move_spacing).with(player_1)
      expect do
        expect(game_1.attack_random_ship(player_1, player_2)).to be_truthy
      end.to change(Move, :count).by(1)
    end
  end

  describe '#get_sinking_ship' do
    it 'returns nil' do
      create(:layout, game: game_1, player: player_2, ship: ship, x: 3, y: 5,
                      vertical: true)
      expect(game_1.get_sinking_ship(player_2)).to be_nil
    end

    it 'returns an unsunk ship layout with a hit' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      expect(game_1.get_sinking_ship(player_2)).to eq(layout)
    end
  end

  describe '#again?' do
    let(:player) { build(:player, id: 1) }

    it 'returns true' do
      allow(game_1).to receive(:rand_n) { 1 }
      expect(game_1.again?(player)).to be_truthy
    end

    it 'returns true' do
      allow(game_1).to receive(:rand_n) { 95 }
      expect(game_1.again?(player)).to be_truthy
    end

    it 'returns falsey' do
      allow(game_1).to receive(:rand_n) { 96 }
      expect(game_1.again?(player)).to be_falsey
    end

    it 'returns falsey' do
      player.id = 2
      allow(game_1).to receive(:rand_n) { 97 }
      expect(game_1.again?(player)).to be_falsey
    end
  end

  describe '#rand_n' do
    it 'returns a random number' do
      result = game_1.rand_n(0, 9)
      expect(result[0]).to be_a(Integer)
      expect(result[0]).to be_between(0, 9)
    end
  end

  describe '#get_totally_random_move' do
    it 'returns a random move' do
      result = game_1.get_totally_random_move(player_1)
      expect(result[0]).to be_a(Integer)
      expect(result[1]).to be_a(Integer)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns a random move after calling get_totally_random_move again' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      allow(game_1).to receive(:rand_col_row).and_return([3, 5], [0, 0])
      game_1.get_totally_random_move(player_1)
    end
  end

  describe '#get_random_move_spacing' do
    it 'returns a random move' do
      result = game_1.get_random_move_spacing(player_1)
      expect(result[0]).to be_a(Integer)
      expect(result[1]).to be_a(Integer)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns a totally random move instead' do
      allow(game_1).to receive(:get_possible_spacing_moves).with(player_1) { [] } # rubocop:disable Metrics/LineLength
      expect(game_1).to receive(:get_totally_random_move).with(player_1)
      game_1.get_random_move_spacing(player_1)
    end
  end

  describe '#get_possible_spacing_moves' do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
    it 'returns possible moves based on previous moves spacing' do
      result = game_1.get_possible_spacing_moves(player_1)
      expected = [[[0, 0], 3], [[0, 1], 5], [[0, 2], 5], [[0, 3], 5], [[0, 4], 5], [[0, 5], 5], [[0, 6], 5], [[0, 7], 5], [[0, 8], 5], [[0, 9], 3], # rubocop:disable Metrics/LineLength
                  [[1, 0], 5], [[1, 1], 8], [[1, 2], 8], [[1, 3], 8], [[1, 4], 8], [[1, 5], 8], [[1, 6], 8], [[1, 7], 8], [[1, 8], 8], [[1, 9], 5], # rubocop:disable Metrics/LineLength
                  [[2, 0], 5], [[2, 1], 8], [[2, 2], 8], [[2, 3], 8], [[2, 4], 8], [[2, 5], 8], [[2, 6], 8], [[2, 7], 8], [[2, 8], 8], [[2, 9], 5], # rubocop:disable Metrics/LineLength
                  [[3, 0], 5], [[3, 1], 8], [[3, 2], 8], [[3, 3], 8], [[3, 4], 8], [[3, 5], 8], [[3, 6], 8], [[3, 7], 8], [[3, 8], 8], [[3, 9], 5], # rubocop:disable Metrics/LineLength
                  [[4, 0], 5], [[4, 1], 8], [[4, 2], 8], [[4, 3], 8], [[4, 4], 8], [[4, 5], 8], [[4, 6], 8], [[4, 7], 8], [[4, 8], 8], [[4, 9], 5], # rubocop:disable Metrics/LineLength
                  [[5, 0], 5], [[5, 1], 8], [[5, 2], 8], [[5, 3], 8], [[5, 4], 8], [[5, 5], 8], [[5, 6], 8], [[5, 7], 8], [[5, 8], 8], [[5, 9], 5], # rubocop:disable Metrics/LineLength
                  [[6, 0], 5], [[6, 1], 8], [[6, 2], 8], [[6, 3], 8], [[6, 4], 8], [[6, 5], 8], [[6, 6], 8], [[6, 7], 8], [[6, 8], 8], [[6, 9], 5], # rubocop:disable Metrics/LineLength
                  [[7, 0], 5], [[7, 1], 8], [[7, 2], 8], [[7, 3], 8], [[7, 4], 8], [[7, 5], 8], [[7, 6], 8], [[7, 7], 8], [[7, 8], 8], [[7, 9], 5], # rubocop:disable Metrics/LineLength
                  [[8, 0], 5], [[8, 1], 8], [[8, 2], 8], [[8, 3], 8], [[8, 4], 8], [[8, 5], 8], [[8, 6], 8], [[8, 7], 8], [[8, 8], 8], [[8, 9], 5], # rubocop:disable Metrics/LineLength
                  [[9, 0], 3], [[9, 1], 5], [[9, 2], 5], [[9, 3], 5], [[9, 4], 5], [[9, 5], 5], [[9, 6], 5], [[9, 7], 5], [[9, 8], 5], [[9, 9], 3]] # rubocop:disable Metrics/LineLength
      expect(result).to eq(expected)
    end

    it 'returns possible moves based on previous moves spacing' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      result = game_1.get_possible_spacing_moves(player_1)
      expected = [[[0, 0], 3], [[0, 1], 5], [[0, 2], 5], [[0, 3], 5], [[0, 4], 5], [[0, 5], 5], [[0, 6], 5], [[0, 7], 5], [[0, 8], 5], [[0, 9], 3], # rubocop:disable Metrics/LineLength
                  [[1, 0], 5], [[1, 1], 8], [[1, 2], 8], [[1, 3], 8], [[1, 4], 8], [[1, 5], 8], [[1, 6], 8], [[1, 7], 8], [[1, 8], 8], [[1, 9], 5], # rubocop:disable Metrics/LineLength
                  [[2, 0], 5], [[2, 1], 8], [[2, 2], 8], [[2, 3], 8], [[2, 4], 7], [[2, 5], 7], [[2, 6], 7], [[2, 7], 8], [[2, 8], 8], [[2, 9], 5], # rubocop:disable Metrics/LineLength
                  [[3, 0], 5], [[3, 1], 8], [[3, 2], 8], [[3, 3], 8], [[3, 4], 7],              [[3, 6], 7], [[3, 7], 8], [[3, 8], 8], [[3, 9], 5], # rubocop:disable Metrics/LineLength
                  [[4, 0], 5], [[4, 1], 8], [[4, 2], 8], [[4, 3], 8], [[4, 4], 7], [[4, 5], 7], [[4, 6], 7], [[4, 7], 8], [[4, 8], 8], [[4, 9], 5], # rubocop:disable Metrics/LineLength
                  [[5, 0], 5], [[5, 1], 8], [[5, 2], 8], [[5, 3], 8], [[5, 4], 8], [[5, 5], 8], [[5, 6], 8], [[5, 7], 8], [[5, 8], 8], [[5, 9], 5], # rubocop:disable Metrics/LineLength
                  [[6, 0], 5], [[6, 1], 8], [[6, 2], 8], [[6, 3], 8], [[6, 4], 8], [[6, 5], 8], [[6, 6], 8], [[6, 7], 8], [[6, 8], 8], [[6, 9], 5], # rubocop:disable Metrics/LineLength
                  [[7, 0], 5], [[7, 1], 8], [[7, 2], 8], [[7, 3], 8], [[7, 4], 8], [[7, 5], 8], [[7, 6], 8], [[7, 7], 8], [[7, 8], 8], [[7, 9], 5], # rubocop:disable Metrics/LineLength
                  [[8, 0], 5], [[8, 1], 8], [[8, 2], 8], [[8, 3], 8], [[8, 4], 8], [[8, 5], 8], [[8, 6], 8], [[8, 7], 8], [[8, 8], 8], [[8, 9], 5], # rubocop:disable Metrics/LineLength
                  [[9, 0], 3], [[9, 1], 5], [[9, 2], 5], [[9, 3], 5], [[9, 4], 5], [[9, 5], 5], [[9, 6], 5], [[9, 7], 5], [[9, 8], 5], [[9, 9], 3]] # rubocop:disable Metrics/LineLength
      expect(result).to eq(expected)
    end
  end

  describe '#in_grid?' do
    it 'returns true' do
      expect(game_1.in_grid?(0)).to be_truthy
      expect(game_1.in_grid?(9)).to be_truthy
    end

    it 'returns false' do
      expect(game_1.in_grid?(-1)).to be_falsey
      expect(game_1.in_grid?(10)).to be_falsey
    end
  end

  describe '#hit_miss_grid' do # rubocop:disable Metrics/BlockLength
    it 'returns a grid of hits and misses' do
      result = game_1.hit_miss_grid(player_1)
      expected = [['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', '']]
      expect(result).to eq(expected)
    end

    it 'returns a grid of hits and misses' do
      layout = create(:layout, game: game_1, player: player_2, ship: ship,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game_1, player: player_1, x: 3, y: 5, layout: layout)
      result = game_1.hit_miss_grid(player_1)
      expected = [['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', 'H', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', ''],
                  ['', '', '', '', '', '', '', '', '', '']]
      expect(result).to eq(expected)
    end
  end

  describe '#get_random_move_lines' do
    it 'gets an x, y coordinate' do
      x, y = game_1.get_random_move_lines(player_1)
      expect(x).to be_a(Integer)
      expect(y).to be_a(Integer)
      expect(x).to be_between(0, 9)
      expect(y).to be_between(0, 9)
    end
  end

  describe '#random_min_col_row' do
    it 'returns indexes for least hit areas' do
      cols = [2, 2, 1]
      rows = [3, 3, 2]
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

  describe '#next_turn!' do
    it 'advances to next player turn' do
      game_1.next_turn!
      expect(game_1.turn).to eq(player_2)
    end
  end

  describe '#declare_winner' do
    before do
      create(:layout, game: game_1, player: player_1, ship: ship)
      create(:layout, game: game_1, player: player_2, ship: ship, sunk: true)
    end

    it 'sets a game winner' do
      game_1.declare_winner
      expect(game_1.winner).to eq(player_1)
    end
  end

  describe '#all_ships_sunk?' do
    before do
      create(:layout, game: game_1, player: player_1, ship: ship)
      create(:layout, game: game_1, player: player_2, ship: ship, sunk: true)
    end

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
