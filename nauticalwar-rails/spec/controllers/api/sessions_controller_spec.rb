# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::SessionsController do
  describe 'POST #create' do
    let(:player) { create(:player, :confirmed) }
    let(:params) do
      { email: player.email, password: 'changeme', format: :json }
    end
    let(:json) { response.parsed_body }

    it 'returns a player id' do
      post(:create, params:)
      expect(json['id']).to eq(Player.last.id)
    end

    it 'returns an error' do
      post :create, params: { format: :json }
      expect(json['error']).to eq('Player not found')
    end
  end

  describe 'GET #destroy' do
    it 'returns redirect' do
      get :destroy, params: { format: :json }
      expect(response.body).to be_blank
    end
  end
end
