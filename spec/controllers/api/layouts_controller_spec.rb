# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::LayoutsController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player) { create(:player, :confirmed) }

  before do
    Game.create_ships
    login(player)
  end

  describe 'GET #create' do
    let(:json) { JSON.parse(response.body) }
    let(:player_2) { create(:player, :confirmed) }
    let(:game) do
      create(:game, player_1: player, player_2: player_2, turn: player)
    end

    it 'game not found' do
      post :create
      expect(json['errors']).to eq('game not found')
    end

    it 'creates ship layouts' do
      layout = { ships: [
        { name: 'Carrier',     x: 1, y: 1, vertical: 1 },
        { name: 'Battleship',  x: 2, y: 7, vertical: 0 },
        { name: 'Destroyer',   x: 5, y: 3, vertical: 1 },
        { name: 'Submarine',   x: 7, y: 6, vertical: 1 },
        { name: 'Patrol Boat', x: 6, y: 1, vertical: 0 }
      ] }.to_json
      params = { game_id: game.id, layout: layout }
      expect do
        post :create, params: params, format: :json
      end.to change(Layout, :count).by(5)
      expect(json['player_1_layed_out']).to eq('1')
    end
  end
end
