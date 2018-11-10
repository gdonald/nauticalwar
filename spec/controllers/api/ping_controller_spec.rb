# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PingController, type: :controller do
  let(:player) { create(:player) }

  before do
    player.confirm
    login(player)
  end

  describe 'GET #index' do
    let(:json) { JSON.parse(response.body) }

    it 'returns http success' do
      get :index, params: { format: :json }
      expect(response).to be_successful
      expected = { 'id' => player.id }
      expect(json).to eq(expected)
    end
  end
end
