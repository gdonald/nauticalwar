# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::FriendsController do
  let(:player1) { create(:player, :confirmed) }
  let(:player2) { create(:player, :confirmed) }
  let(:json) { response.parsed_body }

  describe 'GET #index' do
    let(:friend) { create(:friend, player1:, player2:) }

    before { friend }

    it 'returns friend ids' do
      get :index, params: {}, session: { player_id: player1.id }
      expected = { 'ids' => [player2.id] }
      expect(json).to eq(expected)
    end
  end

  describe 'GET #show' do
    it 'returns true' do
      create(:friend, player1:, player2:)
      get :show, params: { id: player2.id }, session: { player_id: player1.id }
      expected = { 'status' => true }
      expect(json).to eq(expected)
    end

    it 'returns false' do
      get :show, params: { id: 0 }, session: { player_id: player1.id }
      expected = { 'status' => false }
      expect(json).to eq(expected)
    end
  end

  describe 'POST #create' do
    it 'creates a friend, returns friend id' do
      post :create, params: { id: player2.id },
                    session: { player_id: player1.id }
      expect(json['status']).to eq(player2.id)
    end
  end

  describe 'POST #destroy' do
    let(:friend) { create(:friend, player1:, player2:) }

    before { friend }

    it 'destroys a friend, returns friend id' do
      post :destroy, params: { id: player2.id },
                     session: { player_id: player1.id }
      expect(json['status']).to eq(player2.id)
    end
  end
end
