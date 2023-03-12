# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::EnemiesController do
  let(:player1) { create(:player, :confirmed) }
  let(:player2) { create(:player, :confirmed) }
  let(:json) { response.parsed_body }

  describe 'POST #create' do
    it 'creates a enemy, returns enemy id' do
      post :create, params: { id: player2.id },
                    session: { player_id: player1.id }
      expect(json['status']).to eq(player2.id)
    end
  end
end
