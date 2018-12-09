# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::FriendsController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let(:json) { JSON.parse(response.body) }

  describe 'GET #index' do
    let!(:friend) { create(:friend, player_1: player_1, player_2: player_2) }

    it 'returns friend ids' do
      get :index, params: {}, session: { player_id: player_1.id }
      expected = { 'ids' => [player_2.id] }
      expect(json).to eq(expected)
    end
  end

  describe 'POST #create' do
    it 'creates a friend, returns friend id' do
      post :create, params: { id: player_2.id }, session: { player_id: player_1.id }
      expect(json['status']).to eq(player_2.id)
    end
  end

  describe 'POST #destroy' do
    let!(:friend) { create(:friend, player_1: player_1, player_2: player_2) }

    it 'destroys a friend, returns friend id' do
      post :destroy, params: { id: player_2.id }, session: { player_id: player_1.id }
      expect(json['status']).to eq(player_2.id)
    end
  end
end
