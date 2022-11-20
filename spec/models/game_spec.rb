# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game do
  let_it_be(:player1, reload: true) { create(:player) }
  let_it_be(:player2, reload: true) { create(:player) }
  let_it_be(:game1, reload: true) do
    create(:game, shots_per_turn: 5, player1:, player2:, turn: player1)
  end
  let_it_be(:game2) do
    create(:game, player1:, player2:, turn: player2)
  end

  let(:player3) { create(:player) }
  let(:ship) { Ship.first }

  before_all do
    described_class.create_ships
  end

  describe '#layouts_for_player' do
    let!(:layout1) do
      create(:layout, game: game1, ship:,
                      player: player1)
    end
    let!(:layout2) do
      create(:layout, game: game1, ship:,
                      player: player2)
    end

    it 'returns player layouts' do
      expect(game1.layouts_for_player(player1)).to eq([layout1])
      expect(game1.layouts_for_player(player2)).to eq([layout2])
    end
  end

  describe '#layouts_for_opponent' do
    let!(:layout1) do
      create(:layout,
             game: game1,
             ship:,
             player: player1,
             sunk: true)
    end
    let!(:layout2) do
      create(:layout,
             game: game1,
             ship:,
             player: player2,
             sunk: true)
    end

    it 'returns player layouts' do
      expect(game1.layouts_for_opponent(player1)).to eq([layout1])
      expect(game1.layouts_for_opponent(player2)).to eq([layout2])
    end
  end

  describe '#can_attack?' do
    it 'returns false when there is a winner' do
      game1.winner = player1
      expect(game1).not_to be_can_attack(player1)
    end

    it 'returns false when not player1 turn' do
      game1.turn = player2
      expect(game1).not_to be_can_attack(player1)
    end

    it 'returns true when no winner and is player turn' do
      expect(game1).to be_can_attack(player1)
    end
  end

  describe '#parse_shots' do
    let(:json) do
      [{ x: 5, y: 5 },
       { x: 4, y: 6 },
       { x: 6, y: 6 },
       { x: 3, y: 7 },
       { x: 2, y: 8 },
       { x: 7, y: 9 }].to_json
    end

    it 'parses json shots' do
      expected = [{ 'x' => 5, 'y' => 5 },
                  { 'x' => 4, 'y' => 6 },
                  { 'x' => 6, 'y' => 6 },
                  { 'x' => 3, 'y' => 7 },
                  { 'x' => 2, 'y' => 8 }]
      expect(game1.parse_shots(json)).to eq(expected)
    end
  end

  describe '#parse_ships' do
    let(:json) do
      { ships: [
        { name: 'Carrier', x: 1, y: 1, vertical: 1 },
        { name: 'Battleship',  x: 2, y: 7, vertical: 0 },
        { name: 'Destroyer',   x: 5, y: 3, vertical: 1 },
        { name: 'Submarine',   x: 7, y: 6, vertical: 1 },
        { name: 'Patrol Boat', x: 6, y: 1, vertical: 0 }
      ] }.to_json
    end

    it 'returns an array of ships' do
      expected = [
        { 'name' => 'Carrier', 'x' => 1, 'y' => 1, 'vertical' => 1 },
        { 'name' => 'Battleship',  'x' => 2, 'y' => 7, 'vertical' => 0 },
        { 'name' => 'Destroyer',   'x' => 5, 'y' => 3, 'vertical' => 1 },
        { 'name' => 'Submarine',   'x' => 7, 'y' => 6, 'vertical' => 1 },
        { 'name' => 'Patrol Boat', 'x' => 6, 'y' => 1, 'vertical' => 0 }
      ]
      expect(game1.parse_ships(json)).to eq(expected)
    end
  end

  describe '#bot_attack!' do
    let_it_be(:bot) { create(:player, :bot, strength: 3) }
    let_it_be(:game) do
      create(:game, shots_per_turn: 5, player1:, player2: bot, turn: bot)
    end

    before_all do
      Ship.ordered.each do |ship|
        Layout.set_location(game, player1, ship, [0, 1].sample.zero?)
      end
      game.update(player1_layed_out: true)
      game.bot_layout
    end

    describe 'with a 5-shot game' do
      it 'creates 5 bot moves' do
        expect do
          game.bot_attack!
        end.to change(Move, :count).by(5)
                                   .and change { bot.reload.activity }.by(1)
        expect(game.winner).to be_nil
        expect(game.turn).to eq(player1)
      end
    end

    describe 'with a 4-shot game' do
      let(:game) do
        create(:game, shots_per_turn: 4, player1:, player2: bot, turn: bot)
      end

      it 'creates 4 bot moves' do
        expect do
          game.bot_attack!
        end.to change(Move, :count).by(4)
                                   .and change { bot.reload.activity }.by(1)
        expect(game.turn).to eq(player1)
      end
    end

    describe 'with a 3-shot game' do
      let(:game) do
        create(:game, shots_per_turn: 3, player1:, player2: bot, turn: bot)
      end

      it 'creates 3 bot moves' do
        expect do
          game.bot_attack!
        end.to change(Move, :count).by(3)
                                   .and change { bot.reload.activity }.by(1)
        expect(game.turn).to eq(player1)
      end
    end

    describe 'with a 2-shot game' do
      let(:game) do
        create(:game, shots_per_turn: 2, player1:, player2: bot, turn: bot)
      end

      it 'creates 2 bot moves' do
        expect do
          game.bot_attack!
        end.to change(Move, :count).by(2)
                                   .and change { bot.reload.activity }.by(1)
        expect(game.turn).to eq(player1)
      end
    end

    describe 'with a 1-shot game' do
      let(:game) do
        create(:game, shots_per_turn: 1, player1:, player2: bot, turn: bot)
      end

      it 'creates 1 bot move' do
        expect do
          game.bot_attack!
        end.to change(Move, :count).by(1)
                                   .and change { bot.reload.activity }.by(1)
        expect(game.turn).to eq(player1)
      end
    end
  end

  describe '#bot_attack_1!' do
    let(:bot) { create(:player, :bot, strength: 3) }
    let!(:game) do
      create(:game, player1:, player2: bot, turn: player1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let(:move) do
        create(:move, game:, player: bot, x: 3, y: 5, layout:)
      end

      before { move }

      it 'creates 1 bot move' do
        expect do
          game.bot_attack_1!
        end.to change(Move, :count).by(1)
      end
    end

    describe 'with a non-sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      before { layout }

      it 'creates 1 bot move' do
        expect do
          game.bot_attack_1!
        end.to change(Move, :count).by(1)
      end
    end
  end

  describe '#bot_attack_2!' do
    let(:bot) { create(:player, :bot, strength: 1) }
    let!(:game) do
      create(:game, shots_per_turn: 2, player1:, player2: bot, turn: player1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let(:move) do
        create(:move, game:, player: bot, x: 3, y: 5, layout:)
      end

      before { move }

      it 'creates 2 bot moves' do
        expect do
          game.bot_attack_2!
        end.to change(Move, :count).by(2)
      end
    end

    describe 'with a non-sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      before { layout }

      it 'creates 2 bot moves' do
        expect do
          game.bot_attack_2!
        end.to change(Move, :count).by(2)
      end
    end
  end

  describe '#bot_attack_3!' do
    let(:bot) { create(:player, :bot, strength: 3) }
    let!(:game) do
      create(:game, shots_per_turn: 3, player1:, player2: bot, turn: player1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let(:move) do
        create(:move, game:, player: bot, x: 3, y: 5, layout:)
      end

      before { move }

      it 'creates 3 bot moves' do
        expect do
          game.bot_attack_3!
        end.to change(Move, :count).by(3)
      end
    end

    describe 'with a non-sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      before { layout }

      it 'creates 3 bot moves' do
        expect do
          game.bot_attack_3!
        end.to change(Move, :count).by(3)
      end
    end
  end

  describe '#bot_attack_4!' do
    let(:bot) { create(:player, :bot, strength: 3) }
    let!(:game) do
      create(:game, shots_per_turn: 4, player1:, player2: bot, turn: player1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let(:move) do
        create(:move, game:, player: bot, x: 3, y: 5, layout:)
      end

      before { move }

      it 'creates 4 bot moves' do
        expect do
          game.bot_attack_4!
        end.to change(Move, :count).by(4)
      end
    end

    describe 'with a non-sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      before { layout }

      it 'creates 4 bot moves' do
        expect do
          game.bot_attack_4!
        end.to change(Move, :count).by(4)
      end
    end
  end

  describe '#bot_attack_5!' do
    let(:bot) { create(:player, :bot, strength: 3) }
    let!(:game) do
      create(:game, player1:, player2: bot, turn: player1)
    end

    describe 'with a sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let(:move) do
        create(:move, game:, player: bot, x: 3, y: 5, layout:)
      end

      before { move }

      it 'creates 5 bot moves' do
        expect do
          game.bot_attack_5!
        end.to change(Move, :count).by(5)
      end
    end

    describe 'with a non-sinking ship' do
      let(:layout) do
        create(:layout, game:, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end

      before { layout }

      it 'creates 5 bot moves' do
        expect do
          game.bot_attack_5!
        end.to change(Move, :count).by(5)
      end
    end
  end

  describe '#move_exists?' do
    it 'returns false' do
      expect(game1).not_to be_move_exists(player1, 0, 0)
    end

    describe 'when there is a move' do
      let(:layout) do
        create(:layout, game: game1, player: player1, ship: Ship.last,
                        x: 3, y: 5, vertical: true)
      end
      let(:move) do
        create(:move, game: game1, player: player2, x: 3, y: 5,
                      layout:)
      end

      before { move }

      it 'returns true' do
        expect(game1).to be_move_exists(player2, 3, 5)
      end
    end
  end

  describe '#create_ship_layout' do
    it 'creates ship layout' do
      hash = { 'name' => 'Carrier', 'x' => 1, 'y' => 1, 'vertical' => 1 }
      expect do
        game1.create_ship_layout(player1, hash)
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
      expect do
        game1.create_ship_layouts(player1, layout)
      end.to change(Layout, :count).by(5)
      expect(game1.player1_layed_out).to be_truthy
    end
  end

  describe '#vertical_location' do
    it 'returns a row and col' do
      result = game1.vertical_location(player1, ship)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end
  end

  describe '#horizontal_location' do
    it 'returns a row and col' do
      result = game1.horizontal_location(player1, ship)
      expect(result).to be_a(Array)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end
  end

  describe '#attack_known_vert' do
    it 'creates and returns a move on a vertical layout' do
      layout = create(:layout, game: game1, player: player2, ship: Ship.last,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      create(:move, game: game1, player: player1, x: 3, y: 6, layout:)
      expect do
        game1.attack_known_vert(player1, player2, layout.moves)
      end.to change(Move, :count).by(1)
    end

    it 'creates and returns a move on a horizontal layout' do
      layout = create(:layout, game: game1, player: player2, ship: Ship.last,
                               x: 3, y: 5)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      create(:move, game: game1, player: player1, x: 4, y: 5, layout:)
      expect do
        game1.attack_known_vert(player1, player2, layout.moves)
      end.to change(Move, :count).by(1)
    end
  end

  describe '#attack_vertical' do
    it 'returns possible vertical moves' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      result = game1.attack_vertical(player1, layout.moves)
      expect(result).to eq([[3, 3], [4, 6]])
    end
  end

  describe '#attack_horizontal' do
    it 'returns possible horizontal moves' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: false)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      result = game1.attack_horizontal(player1, layout.moves)
      expect(result).to eq([[2, 4], [5, 5]])
    end
  end

  describe '#attack_unknown_vert' do
    it 'creates a move and returns true' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      hit = create(:move, game: game1, player: player1, x: 3, y: 5,
                          layout:)
      create(:move, game: game1, player: player1, x: 3, y: 6, layout:)
      create(:move, game: game1, player: player1, x: 4, y: 5)
      create(:move, game: game1, player: player1, x: 2, y: 5)
      expect(game1.attack_unknown_vert(player1, player2, hit)).to be_truthy
      move = game1.moves.last
      expect(move.x).to eq(3)
      expect(move.y).to eq(4)
    end

    it 'returns false' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      hit = create(:move, game: game1, player: player1, x: 3, y: 5,
                          layout:)
      create(:move, game: game1, player: player1, x: 3, y: 6, layout:)
      create(:move, game: game1, player: player1, x: 4, y: 5)
      create(:move, game: game1, player: player1, x: 2, y: 5)
      create(:move, game: game1, player: player1, x: 3, y: 4)
      expect(game1.attack_unknown_vert(player1, player2, hit)).to be_falsey
    end
  end

  describe '#normal_range' do
    it 'returns a range from 0 to 9' do
      expect(game1.normal_range(-1, 10)).to eq((0..9))
    end

    it 'returns a range from 2 to 7' do
      expect(game1.normal_range(2, 7)).to eq((2..7))
    end
  end

  describe '#attack_sinking_ship' do
    it 'returns nil' do
      result = game1.attack_sinking_ship(player1, player2)
      expect(result).not_to be_present
    end

    it 'calls attack_known_vert' do
      allow(game1).to receive(:attack_known_vert)
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      create(:move, game: game1, player: player1, x: 3, y: 6, layout:)
      moves = layout.moves
      game1.attack_sinking_ship(player1, player2)
      expect(game1).to have_received(:attack_known_vert)
        .with(player1, player2, moves)
    end

    it 'calls attack_unknown_vert' do
      allow(game1).to receive(:attack_unknown_vert)
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      moves = layout.moves
      game1.attack_sinking_ship(player1, player2)
      expect(game1).to have_received(:attack_unknown_vert)
        .with(player1, player2, moves.first)
    end
  end

  describe '#attack_random_ship' do
    it 'attacks a random ship' do
      expect do
        game1.attack_random_ship(player1, player2)
      end.to change(Move, :count).by(1)
    end

    it 'attacks a random ship using get_random_move_spacing' do
      allow(game1).to receive(:get_random_move_spacing)
      layout = instance_double(Layout)
      allow(layout).to receive(:nil?).once.and_return(true)
      allow(game1).to receive(:again?).with(player1).and_return(true)
      expect do
        expect(game1.attack_random_ship(player1, player2)).to be_truthy
      end.to change(Move, :count).by(1)
      expect(game1).to have_received(:get_random_move_spacing).with(player1)
    end
  end

  describe '#get_sinking_ship' do
    it 'returns nil' do
      create(:layout, game: game1, player: player2, ship:, x: 3, y: 5,
                      vertical: true)
      expect(game1.get_sinking_ship(player2)).to be_nil
    end

    it 'returns an unsunk ship layout with a hit' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      expect(game1.get_sinking_ship(player2)).to eq(layout)
    end
  end

  describe '#again?' do
    let(:player) { build(:player, id: 1) }

    it 'returns true' do
      allow(game1).to receive(:rand_n).and_return(1)
      expect(game1).to be_again(player)
    end

    it 'with 95 returns true' do
      allow(game1).to receive(:rand_n).and_return(95)
      expect(game1).to be_again(player)
    end

    it 'returns falsey' do
      allow(game1).to receive(:rand_n).and_return(96)
      expect(game1).not_to be_again(player)
    end

    it 'with 97 returns falsey' do
      player.id = 2
      allow(game1).to receive(:rand_n).and_return(97)
      expect(game1).not_to be_again(player)
    end
  end

  describe '#rand_n' do
    it 'returns a random number' do
      result = game1.rand_n(0, 9)
      expect(result[0]).to be_a(Integer)
      expect(result[0]).to be_between(0, 9)
    end
  end

  describe '#get_totally_random_move' do
    it 'returns a random move' do
      result = game1.get_totally_random_move(player1)
      expect(result[0]).to be_a(Integer)
      expect(result[1]).to be_a(Integer)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns a random move after calling get_totally_random_move again' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      allow(game1).to receive(:rand_col_row)
      game1.get_totally_random_move(player1)
      expect(game1).to have_received(:rand_col_row)
    end
  end

  describe '#get_random_move_spacing' do
    it 'returns a random move' do
      result = game1.get_random_move_spacing(player1)
      expect(result[0]).to be_a(Integer)
      expect(result[1]).to be_a(Integer)
      expect(result[0]).to be_between(0, 9)
      expect(result[1]).to be_between(0, 9)
    end

    it 'returns a totally random move instead' do
      allow(game1).to receive(:get_totally_random_move)
      allow(game1).to receive(:get_possible_spacing_moves).with(player1).and_return([])
      game1.get_random_move_spacing(player1)
      expect(game1).to have_received(:get_totally_random_move).with(player1)
    end
  end

  describe '#get_possible_spacing_moves' do # rubocop:disable /BlockLength, Metrics/
    it 'returns possible moves based on previous moves spacing' do
      result = game1.get_possible_spacing_moves(player1)
      expected = [[[0, 0], 3], [[0, 1], 5], [[0, 2], 5], [[0, 3], 5], [[0, 4], 5], [[0, 5], 5], [[0, 6], 5], [[0, 7], 5], [[0, 8], 5], [[0, 9], 3], # rubocop:disable Layout/LineLength
                  [[1, 0], 5], [[1, 1], 8], [[1, 2], 8], [[1, 3], 8], [[1, 4], 8], [[1, 5], 8], [[1, 6], 8], [[1, 7], 8], [[1, 8], 8], [[1, 9], 5], # rubocop:disable Layout/LineLength
                  [[2, 0], 5], [[2, 1], 8], [[2, 2], 8], [[2, 3], 8], [[2, 4], 8], [[2, 5], 8], [[2, 6], 8], [[2, 7], 8], [[2, 8], 8], [[2, 9], 5], # rubocop:disable Layout/LineLength
                  [[3, 0], 5], [[3, 1], 8], [[3, 2], 8], [[3, 3], 8], [[3, 4], 8], [[3, 5], 8], [[3, 6], 8], [[3, 7], 8], [[3, 8], 8], [[3, 9], 5], # rubocop:disable Layout/LineLength
                  [[4, 0], 5], [[4, 1], 8], [[4, 2], 8], [[4, 3], 8], [[4, 4], 8], [[4, 5], 8], [[4, 6], 8], [[4, 7], 8], [[4, 8], 8], [[4, 9], 5], # rubocop:disable Layout/LineLength
                  [[5, 0], 5], [[5, 1], 8], [[5, 2], 8], [[5, 3], 8], [[5, 4], 8], [[5, 5], 8], [[5, 6], 8], [[5, 7], 8], [[5, 8], 8], [[5, 9], 5], # rubocop:disable Layout/LineLength
                  [[6, 0], 5], [[6, 1], 8], [[6, 2], 8], [[6, 3], 8], [[6, 4], 8], [[6, 5], 8], [[6, 6], 8], [[6, 7], 8], [[6, 8], 8], [[6, 9], 5], # rubocop:disable Layout/LineLength
                  [[7, 0], 5], [[7, 1], 8], [[7, 2], 8], [[7, 3], 8], [[7, 4], 8], [[7, 5], 8], [[7, 6], 8], [[7, 7], 8], [[7, 8], 8], [[7, 9], 5], # rubocop:disable Layout/LineLength
                  [[8, 0], 5], [[8, 1], 8], [[8, 2], 8], [[8, 3], 8], [[8, 4], 8], [[8, 5], 8], [[8, 6], 8], [[8, 7], 8], [[8, 8], 8], [[8, 9], 5], # rubocop:disable Layout/LineLength
                  [[9, 0], 3], [[9, 1], 5], [[9, 2], 5], [[9, 3], 5], [[9, 4], 5], [[9, 5], 5], [[9, 6], 5], [[9, 7], 5], [[9, 8], 5], [[9, 9], 3]] # rubocop:disable Layout/LineLength
      expect(result).to eq(expected)
    end

    it 'with a move returns possible moves based on previous moves spacing' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      result = game1.get_possible_spacing_moves(player1)
      expected = [[[0, 0], 3], [[0, 1], 5], [[0, 2], 5], [[0, 3], 5], [[0, 4], 5], [[0, 5], 5], [[0, 6], 5], [[0, 7], 5], [[0, 8], 5], [[0, 9], 3], # rubocop:disable Layout/LineLength
                  [[1, 0], 5], [[1, 1], 8], [[1, 2], 8], [[1, 3], 8], [[1, 4], 8], [[1, 5], 8], [[1, 6], 8], [[1, 7], 8], [[1, 8], 8], [[1, 9], 5], # rubocop:disable Layout/LineLength
                  [[2, 0], 5], [[2, 1], 8], [[2, 2], 8], [[2, 3], 8], [[2, 4], 7], [[2, 5], 7], [[2, 6], 7], [[2, 7], 8], [[2, 8], 8], [[2, 9], 5], # rubocop:disable Layout/LineLength
                  [[3, 0], 5], [[3, 1], 8], [[3, 2], 8], [[3, 3], 8], [[3, 4], 7],              [[3, 6], 7], [[3, 7], 8], [[3, 8], 8], [[3, 9], 5], # rubocop:disable Layout/LineLength
                  [[4, 0], 5], [[4, 1], 8], [[4, 2], 8], [[4, 3], 8], [[4, 4], 7], [[4, 5], 7], [[4, 6], 7], [[4, 7], 8], [[4, 8], 8], [[4, 9], 5], # rubocop:disable Layout/LineLength
                  [[5, 0], 5], [[5, 1], 8], [[5, 2], 8], [[5, 3], 8], [[5, 4], 8], [[5, 5], 8], [[5, 6], 8], [[5, 7], 8], [[5, 8], 8], [[5, 9], 5], # rubocop:disable Layout/LineLength
                  [[6, 0], 5], [[6, 1], 8], [[6, 2], 8], [[6, 3], 8], [[6, 4], 8], [[6, 5], 8], [[6, 6], 8], [[6, 7], 8], [[6, 8], 8], [[6, 9], 5], # rubocop:disable Layout/LineLength
                  [[7, 0], 5], [[7, 1], 8], [[7, 2], 8], [[7, 3], 8], [[7, 4], 8], [[7, 5], 8], [[7, 6], 8], [[7, 7], 8], [[7, 8], 8], [[7, 9], 5], # rubocop:disable Layout/LineLength
                  [[8, 0], 5], [[8, 1], 8], [[8, 2], 8], [[8, 3], 8], [[8, 4], 8], [[8, 5], 8], [[8, 6], 8], [[8, 7], 8], [[8, 8], 8], [[8, 9], 5], # rubocop:disable Layout/LineLength
                  [[9, 0], 3], [[9, 1], 5], [[9, 2], 5], [[9, 3], 5], [[9, 4], 5], [[9, 5], 5], [[9, 6], 5], [[9, 7], 5], [[9, 8], 5], [[9, 9], 3]] # rubocop:disable Layout/LineLength
      expect(result).to eq(expected)
    end
  end

  describe '#in_grid?' do
    it 'returns true' do
      expect(game1).to be_in_grid(0)
      expect(game1).to be_in_grid(9)
    end

    it 'returns false' do
      expect(game1).not_to be_in_grid(-1)
      expect(game1).not_to be_in_grid(10)
    end
  end

  describe '#hit_miss_grid' do
    it 'returns a grid of hits and misses' do
      result = game1.hit_miss_grid(player1)
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

    it 'with a hit returns a grid of hits and misses' do
      layout = create(:layout, game: game1, player: player2, ship:,
                               x: 3, y: 5, vertical: true)
      create(:move, game: game1, player: player1, x: 3, y: 5, layout:)
      result = game1.hit_miss_grid(player1)
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
      x, y = game1.get_random_move_lines(player1)
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
      expect(game1.random_min_col_row(cols, rows)).to eq(expected)
    end
  end

  describe '#col_row_moves' do
    it 'returns empty grid' do
      expected = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
      expect(game1.col_row_moves(player1)).to eq(expected)
    end

    it 'returns cols and rows' do
      create(:move, game: game1, player: player1, x: 3, y: 3)
      expected = [[0, 0, 0, 1, 0, 0, 0, 0, 0, 0],
                  [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]]
      expect(game1.col_row_moves(player1)).to eq(expected)
    end
  end

  describe '#calculate_scores' do
    let!(:game1) do
      create(:game, player1:, player2:, turn: player2,
                    winner: player1)
    end
    let!(:game2) do
      create(:game, player1:, player2:, turn: player2,
                    winner: player2)
    end

    it 'scores a game where player 1 wins' do
      game1.calculate_scores
      expect(player1.wins).to eq(1)
      expect(player1.losses).to eq(0)
      expect(player1.rating).to eq(1216)
      expect(player2.wins).to eq(0)
      expect(player2.losses).to eq(1)
      expect(player2.rating).to eq(1184)
    end

    it 'scores a game where player 2 wins' do
      game2.calculate_scores
      expect(player1.wins).to eq(0)
      expect(player1.losses).to eq(1)
      expect(player1.rating).to eq(1184)
      expect(player2.wins).to eq(1)
      expect(player2.losses).to eq(0)
      expect(player2.rating).to eq(1216)
    end
  end

  describe '#calculate_scores_cancel' do
    let!(:game1) do
      create(:game, player1:, player2:, turn: player2,
                    winner: player1)
    end
    let!(:game2) do
      create(:game, player1:, player2:, turn: player2,
                    winner: player2)
    end

    it 'scores a canceled game where player 1 wins' do
      game1.calculate_scores(cancel: true)
      expect(player1.wins).to eq(1)
      expect(player1.losses).to eq(0)
      expect(player1.rating).to eq(1201)
      expect(player2.wins).to eq(0)
      expect(player2.losses).to eq(1)
      expect(player2.rating).to eq(1199)
    end

    it 'scores a canceled game where player 2 wins' do
      game2.calculate_scores(cancel: true)
      expect(player1.wins).to eq(0)
      expect(player1.losses).to eq(1)
      expect(player1.rating).to eq(1199)
      expect(player2.wins).to eq(1)
      expect(player2.losses).to eq(0)
      expect(player2.rating).to eq(1201)
    end
  end

  describe '#next_turn!' do
    it 'advances to next player turn' do
      game1.next_turn!
      expect(game1.turn).to eq(player2)
    end
  end

  describe '#declare_winner' do
    before_all do
      create(:layout, game: game1, player: player1, ship: Ship.first)
      create(:layout, game: game1, player: player2, ship: Ship.first, sunk: true)
    end

    it 'sets a game winner' do
      game1.declare_winner
      expect(game1.winner).to eq(player1)
    end
  end

  describe '#all_ships_sunk?' do
    before_all do
      create(:layout, game: game1, player: player1, ship: Ship.first)
      create(:layout, game: game1, player: player2, ship: Ship.first, sunk: true)
    end

    it 'returns false' do
      expect(game1).not_to be_all_ships_sunk(player1)
    end

    it 'returns true' do
      expect(game1).to be_all_ships_sunk(player2)
    end
  end

  describe '#next_player_turn' do
    it 'returns player2' do
      expect(game1.next_player_turn).to eq(player2)
    end

    it 'returns player1' do
      expect(game2.next_player_turn).to eq(player1)
    end
  end

  describe '#opponent' do
    it 'returns player2' do
      expect(game1.opponent(player1)).to eq(player2)
    end

    it 'returns player1' do
      expect(game1.opponent(player2)).to eq(player1)
    end
  end

  describe '#player' do
    it 'returns player2' do
      expect(game1.player(player1)).to eq(player1)
    end

    it 'returns player1' do
      expect(game1.player(player2)).to eq(player2)
    end
  end

  describe '.create_ships' do
    it 'creates ships' do
      expect(Ship.count).to eq(5)
    end
  end

  describe '#bot_layout' do
    it 'creates bot layouts' do
      expect do
        game1.bot_layout
      end.to change(Layout, :count).by(Ship.count)
      expect(game1.player2_layed_out).to be_truthy
    end
  end

  describe '#guest_layout' do
    it 'creates guest layouts' do
      expect do
        game1.guest_layout
      end.to change(Layout, :count).by(Ship.count)
      expect(game1.player1_layed_out).to be_truthy
    end
  end

  describe '.find_game' do
    let(:id) { game1.id }

    it 'returns a game for player1' do
      expect(described_class.find_game(player1, id)).to eq(game1)
    end

    it 'returns a game for player2' do
      expect(described_class.find_game(player2, id)).to eq(game1)
    end

    it 'returns nil for player3' do
      expect(described_class.find_game(player3, id)).to be_nil
    end

    it 'returns nil for unknown game id' do
      expect(described_class.find_game(player1, 0)).to be_nil
    end
  end

  describe '#t_limit' do
    it 'returns time limit per turn in seconds' do
      travel_to game1.updated_at do
        expect(game1.t_limit).to eq(86_400)
      end
    end
  end

  describe '#moves_for_player' do
    let!(:move1) { create(:move, game: game1, player: player1, x: 0, y: 0) }
    let(:move2) { create(:move, game: game1, player: player2, x: 0, y: 0) }

    before { move2 }

    it 'returns moves for a player' do
      expect(game1.moves_for_player(player1)).to eq([move1])
    end

    it 'returns an empty array' do
      expect(game1.moves_for_player(player3)).to eq([])
    end
  end

  describe '#hit?' do
    let(:layout) do
      create(:layout, game: game1, player: player1, ship:, x: 2, y: 2,
                      vertical: true)
    end

    before { layout }

    it 'returns true' do
      expect(game1).to be_hit(player1, 2, 2)
    end

    it 'returns false' do
      expect(game1).not_to be_hit(player2, 5, 5)
    end
  end

  describe '#empty_neighbors' do
    let!(:layout) do
      create(:layout, game: game1, player: player1, ship:, x: 5, y: 5,
                      vertical: true)
    end
    let!(:hit) do
      create(:move, game: game1, player: player2, x: 5, y: 5, layout:)
    end

    it 'returns 4 empty neighbors for a hit' do
      expected = [[4, 6, 5, 5], [5, 5, 4, 6]]
      expect(game1.empty_neighbors(player2, hit)).to eq(expected)
    end

    it 'returns 3 empty neighbors for a hit' do
      create(:move, game: game1, player: player2, x: 5, y: 6)

      expected = [[4, 6, 5], [5, 5, 4]]
      expect(game1.empty_neighbors(player2, hit)).to eq(expected)
    end

    it 'returns 2 empty neighbors for a hit' do
      create(:move, game: game1, player: player2, x: 5, y: 6)
      create(:move, game: game1, player: player2, x: 5, y: 4)

      expected = [[4, 6], [5, 5]]
      expect(game1.empty_neighbors(player2, hit)).to eq(expected)
    end

    it 'returns 1 empty neighbor for a hit' do
      create(:move, game: game1, player: player2, x: 5, y: 6)
      create(:move, game: game1, player: player2, x: 5, y: 4)
      create(:move, game: game1, player: player2, x: 6, y: 5)

      expected = [[4], [5]]
      expect(game1.empty_neighbors(player2, hit)).to eq(expected)
    end

    it 'returns 0 empty neighborw for a hit' do
      create(:move, game: game1, player: player2, x: 5, y: 6)
      create(:move, game: game1, player: player2, x: 5, y: 4)
      create(:move, game: game1, player: player2, x: 6, y: 5)
      create(:move, game: game1, player: player2, x: 4, y: 5)

      expected = [[], []]
      expect(game1.empty_neighbors(player2, hit)).to eq(expected)
    end
  end
end
