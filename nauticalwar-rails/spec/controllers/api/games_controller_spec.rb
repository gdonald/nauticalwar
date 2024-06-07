# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::GamesController do # rubocop:disable /BlockLength, Metrics/
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:json) { response.parsed_body }
  let(:game_one) do
    create(:game, player1: player_one, player2: player_two, turn: player_one,
                  del_player1: true)
  end
  let!(:game_two) do
    create(:game, player1: player_one, player2: player_two, turn: player_one)
  end
  let!(:game_three) do
    create(:game, player1: player_one, player2: player_two, turn: player_one)
  end

  before do
    Game.create_ships
    game_one
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: {}, session: { player_id: player_one.id }
      expect(json.size).to eq(2)
      expect(json[0]['id']).to eq(game_two.id)
      expect(json[1]['id']).to eq(game_three.id)
    end
  end

  describe 'GET #count' do
    it 'returns http success' do
      get :count, params: {}, session: { player_id: player_one.id }
      expect(json['count']).to eq(2)
    end
  end

  describe 'GET #next' do
    let!(:game) do
      create(:game, player1: player_one, player2: player_two, turn: player_one,
                    player1_layed_out: true, player2_layed_out: true)
    end

    it 'returns http success' do
      get :next, params: {}, session: { player_id: player_one.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'POST #skip' do
    let!(:game) do
      create(:game, player1: player_one, player2: player_two, turn: player_two,
                    player1_layed_out: true, player2_layed_out: true)
    end

    it 'returns http success' do
      travel_to(2.days.from_now) do
        post :skip, params: { id: game.id }, session: { player_id: player_one.id }
        expect(json['status']).to eq(game.id)
      end
    end
  end

  describe 'POST #destroy' do
    let!(:game) do
      create(:game, player1: player_one, player2: player_two, turn: player_two,
                    winner: player_one)
    end

    it 'returns http success' do
      post :destroy, params: { id: game.id },
                     session: { player_id: player_one.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'POST #cancel' do
    let!(:game) do
      create(:game, player1: player_one, player2: player_two, turn: player_two,
                    winner: player_one)
    end

    it 'returns http success' do
      post :cancel, params: { id: game.id }, session: { player_id: player_one.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'GET #my_turn' do
    let!(:game) do
      create(:game, player1: player_one, player2: player_two, turn: player_one)
    end

    it 'returns http success' do
      get :my_turn, params: { id: game.id }, session: { player_id: player_one.id }
      expect(json['status']).to eq(1)
    end
  end

  describe 'GET #show' do
    describe 'game exists' do
      let(:game) do
        create(:game, player1: player_one, player2: player_two, turn: player_two)
      end
      let(:layout) do
        create(:layout, game:, player: player_one, ship: create(:ship),
                        x: 3, y: 5)
      end
      let(:move) do
        create(:move, game:, player: player_two, x: 3, y: 5,
                      layout:)
      end

      before { move }

      it 'returns a game' do
        travel_to(1.day.from_now) do
          get :show, params: { id: game.id },
                     session: { player_id: player_one.id }
          expected = {
            'game' =>
              { 'id' => game.id,
                'player1_id' => player_one.id,
                'player2_id' => player_two.id,
                'player1_name' => player_one.name,
                'player2_name' => player_two.name,
                'turn_id' => player_two.id,
                'winner_id' => '0',
                'updated_at' => game.updated_at.iso8601,
                'player1_layed_out' => '0',
                'player2_layed_out' => '0',
                'rated' => '1',
                'shots_per_turn' => 1,
                't_limit' => 0 },
            'layouts' => [{ 'id' => layout.id,
                            'game_id' => game.id,
                            'player_id' => player_one.id,
                            'ship_id' => layout.ship_id - 1,
                            'x' => 3,
                            'y' => 5,
                            'vertical' => 1 }],
            'moves' => [{ 'x' => 3, 'y' => 5, 'hit' => 'H' }]
          }
          expect(json).to eq(expected)
        end
      end
    end

    it 'returns an error' do
      get :show, params: { id: 0 }, session: { player_id: player_one.id }
      expect(json['error']).to eq('game not found')
    end
  end

  describe 'GET #opponent' do
    describe 'game exists' do
      let(:game) do
        create(:game, player1: player_one, player2: player_two, turn: player_two)
      end
      let(:layout) do
        create(:layout, game:, player: player_two, ship: create(:ship),
                        x: 3, y: 5)
      end
      let(:move) do
        create(:move, game:, player: player_one, x: 3, y: 5,
                      layout:)
      end

      before { move }

      it 'returns a game' do
        travel_to(1.day.from_now) do
          get :opponent, params: { id: game.id },
                         session: { player_id: player_one.id }
          expected = {
            'game' =>
                { 'id' => game.id,
                  'player1_id' => player_one.id,
                  'player2_id' => player_two.id,
                  'player1_name' => player_one.name,
                  'player2_name' => player_two.name,
                  'turn_id' => player_two.id,
                  'winner_id' => '0',
                  'updated_at' => game.updated_at.iso8601,
                  'player1_layed_out' => '0',
                  'player2_layed_out' => '0',
                  'rated' => '1',
                  'shots_per_turn' => 1,
                  't_limit' => 0 },
            'layouts' => [],
            'moves' => [{ 'x' => 3, 'y' => 5, 'hit' => 'H' }]
          }
          expect(json).to eq(expected)
        end
      end
    end

    it 'returns an error' do
      get :opponent, params: { id: 0 }, session: { player_id: player_one.id }
      expect(json['error']).to eq('game not found')
    end
  end

  describe 'POST #attack' do
    let!(:game) do
      create(:game, player1: player_one, player2: player_two, turn: player_one)
    end
    let(:s) do
      [{ x: 5, y: 5 },
       { x: 4, y: 6 },
       { x: 6, y: 6 },
       { x: 3, y: 7 },
       { x: 2, y: 8 },
       { x: 7, y: 9 }].to_json
    end

    it 'returns status of 1' do
      post :attack, params: { id: game.id, s: },
                    session: { player_id: player_one.id }
      expect(json['status']).to eq(1)
      expect(json['error']).to be_nil
    end

    it 'returns status of -1' do
      game.update(turn: player_two)
      post :attack, params: { id: game.id, s: },
                    session: { player_id: player_one.id }
      expect(json['status']).to eq(-1)
      expect(json['error']).to be_nil
    end

    it 'returns not found' do
      post :attack, params: { id: 0, s: }, session: { player_id: player_one.id }
      expect(json['status']).to be_nil
      expect(json['error']).to eq('game not found')
    end
  end
end
