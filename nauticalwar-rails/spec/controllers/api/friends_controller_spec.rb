# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::FriendsController do
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:json) { response.parsed_body }

  describe 'GET #index' do
    let(:friend) { create(:friend, player1: player_one, player2: player_two) }

    before { friend }

    it 'returns friend ids' do
      get :index, params: {}, session: { player_id: player_one.id }
      expected = { 'ids' => [player_two.id] }
      expect(json).to eq(expected)
    end
  end

  describe 'GET #show' do
    it 'returns true' do
      create(:friend, player1: player_one, player2: player_two)
      get :show, params: { id: player_two.id }, session: { player_id: player_one.id }
      expected = { 'status' => true }
      expect(json).to eq(expected)
    end

    it 'returns false' do
      get :show, params: { id: 0 }, session: { player_id: player_one.id }
      expected = { 'status' => false }
      expect(json).to eq(expected)
    end
  end

  describe 'POST #create' do
    it 'creates a friend, returns friend id' do
      post :create, params: { id: player_two.id },
                    session: { player_id: player_one.id }
      expect(json['status']).to eq(player_two.id)
    end
  end

  describe 'POST #destroy' do
    let(:friend) { create(:friend, player1: player_one, player2: player_two) }

    before { friend }

    it 'destroys a friend, returns friend id' do
      post :destroy, params: { id: player_two.id },
                     session: { player_id: player_one.id }
      expect(json['status']).to eq(player_two.id)
    end
  end
end
