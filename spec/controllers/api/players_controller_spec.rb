# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlayersController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player) { create(:player, :confirmed) }

  before do
    login(player)
  end

  describe 'GET #index' do
    let(:json) { JSON.parse(response.body) }

    it 'returns http success' do
      get :index, params: { format: :json }
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
      get :activity, params: { format: :json }
      expect(response).to be_successful
      expected = { 'activity' => 0 }
      expect(json).to eq(expected)
    end
  end
end
