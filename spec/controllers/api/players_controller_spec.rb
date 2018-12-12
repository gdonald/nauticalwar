# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlayersController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player) { create(:player, :confirmed) }

  describe 'GET #index' do
    let(:json) { JSON.parse(response.body) }

    it 'returns http success' do
      get :index, params: { format: :json }, session: { player_id: player.id }
      expect(response).to be_successful
      expect(json[0]['id']).to eq(player.id)
      expect(json[0]['name']).to eq(player.name)
      expect(json[0]['wins']).to eq(0)
      expect(json[0]['losses']).to eq(0)
      expect(json[0]['rating']).to eq(1200)
      expect(json[0]['last']).to eq(0)
      expect(json[0]['bot']).to eq(0)
    end
  end

  describe 'GET #activity' do
    let(:json) { JSON.parse(response.body) }

    it 'returns http success' do
      get :activity, params: { format: :json },
                     session: { player_id: player.id }
      expect(response).to be_successful
      expect(json['activity']).to eq(0)
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
      expect(json['errors']['email']).to eq(["can't be blank", 'is not valid'])
      expect(json['errors']['name']).to eq(["can't be blank"])
      expect(json['errors']['password']).to eq(["can't be blank"])
      expect(json['errors']['password_confirmation']).to eq(["can't be blank"])
    end
  end
end
