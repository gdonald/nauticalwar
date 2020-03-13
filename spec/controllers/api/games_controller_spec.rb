# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::GamesController, type: :controller do # rubocop:disable /BlockLength, Metrics/
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let(:json) { JSON.parse(response.body) }
  let!(:game_1) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                  del_player_1: true)
  end
  let!(:game_2) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_1)
  end
  let!(:game_3) do
    create(:game, player_1: player_1, player_2: player_2, turn: player_1)
  end

  before do
    Game.create_ships
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: {}, session: { player_id: player_1.id }
      expect(json.size).to eq(2)
      expect(json[0]['id']).to eq(game_2.id)
      expect(json[1]['id']).to eq(game_3.id)
    end
  end

  describe 'GET #count' do
    it 'returns http success' do
      get :count, params: {}, session: { player_id: player_1.id }
      expect(json['count']).to eq(2)
    end
  end

  describe 'GET #next' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                    player_1_layed_out: true, player_2_layed_out: true)
    end

    it 'returns http success' do
      get :next, params: {}, session: { player_id: player_1.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'POST #skip' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    player_1_layed_out: true, player_2_layed_out: true)
    end

    it 'returns http success' do
      travel_to(2.days.from_now) do
        post :skip, params: { id: game.id }, session: { player_id: player_1.id }
        expect(json['status']).to eq(game.id)
      end
    end
  end

  describe 'POST #destroy' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_1)
    end

    it 'returns http success' do
      post :destroy, params: { id: game.id },
                     session: { player_id: player_1.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'POST #cancel' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_1)
    end

    it 'returns http success' do
      post :cancel, params: { id: game.id }, session: { player_id: player_1.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'GET #my_turn' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end

    it 'returns http success' do
      get :my_turn, params: { id: game.id }, session: { player_id: player_1.id }
      expect(json['status']).to eq(1)
    end
  end

  describe 'GET #show' do # rubocop:disable Metrics/BlockLength
    describe 'game exists' do # rubocop:disable Metrics/BlockLength
      let(:game) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2)
      end
      let(:layout) do
        create(:layout, game: game, player: player_1, ship: create(:ship),
                        x: 3, y: 5)
      end
      let!(:move) do
        create(:move, game: game, player: player_2, x: 3, y: 5,
                      layout: layout)
      end

      it 'returns a game' do # rubocop:disable Metrics/BlockLength
        travel_to(1.day.from_now) do # rubocop:disable Metrics/BlockLength
          get :show, params: { id: game.id },
                     session: { player_id: player_1.id }
          expected = {
            'game' =>
              { 'id' => game.id,
                'player_1_id' => player_1.id,
                'player_2_id' => player_2.id,
                'player_1_name' => player_1.name,
                'player_2_name' => player_2.name,
                'turn_id' => player_2.id,
                'winner_id' => '0',
                'updated_at' => game.updated_at.iso8601,
                'player_1_layed_out' => '0',
                'player_2_layed_out' => '0',
                'rated' => '1',
                'shots_per_turn' => 1,
                't_limit' => 0 },
            'layouts' => [{ 'id' => layout.id,
                            'game_id' => game.id,
                            'player_id' => player_1.id,
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
      get :show, params: { id: 0 }, session: { player_id: player_1.id }
      expect(json['error']).to eq('game not found')
    end
  end

  describe 'GET #opponent' do # rubocop:disable Metrics/BlockLength
    describe 'game exists' do # rubocop:disable Metrics/BlockLength
      let(:game) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2)
      end
      let(:layout) do
        create(:layout, game: game, player: player_2, ship: create(:ship),
                        x: 3, y: 5)
      end
      let!(:move) do
        create(:move, game: game, player: player_1, x: 3, y: 5,
                      layout: layout)
      end

      it 'returns a game' do
        travel_to(1.day.from_now) do
          get :opponent, params: { id: game.id },
                         session: { player_id: player_1.id }
          expected = {
            'game' =>
                { 'id' => game.id,
                  'player_1_id' => player_1.id,
                  'player_2_id' => player_2.id,
                  'player_1_name' => player_1.name,
                  'player_2_name' => player_2.name,
                  'turn_id' => player_2.id,
                  'winner_id' => '0',
                  'updated_at' => game.updated_at.iso8601,
                  'player_1_layed_out' => '0',
                  'player_2_layed_out' => '0',
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
      get :opponent, params: { id: 0 }, session: { player_id: player_1.id }
      expect(json['error']).to eq('game not found')
    end
  end

  describe 'POST #attack' do # rubocop:disable Metrics/BlockLength
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end
    let(:s) do
      [{ 'x': 5, 'y': 5 },
       { 'x': 4, 'y': 6 },
       { 'x': 6, 'y': 6 },
       { 'x': 3, 'y': 7 },
       { 'x': 2, 'y': 8 },
       { 'x': 7, 'y': 9 }].to_json
    end

    it 'returns status of 1' do
      post :attack, params: { id: game.id, s: s },
                    session: { player_id: player_1.id }
      expect(json['status']).to eq(1)
      expect(json['error']).to eq(nil)
    end

    it 'returns status of -1' do
      game.update(turn: player_2)
      post :attack, params: { id: game.id, s: s },
                    session: { player_id: player_1.id }
      expect(json['status']).to eq(-1)
      expect(json['error']).to eq(nil)
    end

    it 'returns not found' do
      post :attack, params: { id: 0, s: s }, session: { player_id: player_1.id }
      expect(json['status']).to eq(nil)
      expect(json['error']).to eq('game not found')
    end
  end
end
