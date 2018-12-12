# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::EnemiesController, type: :controller do # rubocop:disable Metrics/LineLength, Metrics/BlockLength
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let(:json) { JSON.parse(response.body) }

  describe 'POST #create' do
    it 'creates a enemy, returns enemy id' do
      post :create, params: { id: player_2.id },
           session: { player_id: player_1.id }
      expect(json['status']).to eq(player_2.id)
    end
  end
end