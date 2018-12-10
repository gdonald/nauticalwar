# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlayersController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player) { create(:player, :confirmed) }

  describe 'GET #index' do
    let(:json) { JSON.parse(response.body) }

    it 'returns http success' do
      get :index, params: { format: :json }, session: { player_id: player.id }
      expect(response).to be_successful
      expected = [{ 'id' => player.id,
                    'name' => player.name,
                    'wins' => 0,
                    'losses' => 0,
                    'rating' => 1200,
                    'last' => 0 }]
      expect(json).to eq(expected)
    end
  end

  describe 'GET #activity' do
    let(:json) { JSON.parse(response.body) }

    it 'returns http success' do
      get :activity, params: { format: :json },
                     session: { player_id: player.id }
      expect(response).to be_successful
      expected = { 'activity' => 0 }
      expect(json).to eq(expected)
    end
  end

  describe 'POST #create' do
    let(:params) do
      { email: 'foo@bar.com',
        name: 'foo',
        password: 'changeme',
        password_confirmation: 'changeme' }
    end
    let(:json) { JSON.parse(response.body) }
    let(:player) { Player.last }

    it 'creates a player' do
      expect do
        post :create, params: params
      end.to change(Player, :count).by(1)
      expect(json['id']).to eq(player.id)
    end

    it 'returns errors' do
      expect do
        post :create, params: {}
      end.to change(Player, :count).by(0)
      expected = { 'email' => ["can't be blank", 'is not valid'],
                   'name' => ["can't be blank"],
                   'password' => ["can't be blank"],
                   'password_confirmation' => ["can't be blank"] }
      expect(json['errors']).to eq(expected)
    end
  end
end
