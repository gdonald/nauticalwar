# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::GamesController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
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
    login(player_1)
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(json.size).to eq(2)
      expect(json[0]['id']).to eq(game_2.id)
      expect(json[1]['id']).to eq(game_3.id)
    end
  end

  describe 'GET #count' do
    it 'returns http success' do
      get :count
      expect(json['count']).to eq(2)
    end
  end

  describe 'GET #next' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                    player_1_layed_out: true, player_2_layed_out: true)
    end

    it 'returns http success' do
      get :next
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
        post :skip, params: { id: game.id }
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
      post :destroy, params: { id: game.id }
      expect(json['status']).to eq(game.id)
    end
  end

  describe 'POST #cancel' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                    winner: player_1)
    end

    it 'returns http success' do
      post :cancel, params: { id: game.id }
      expect(json['status']).to eq(game.id)
    end
  end
end
