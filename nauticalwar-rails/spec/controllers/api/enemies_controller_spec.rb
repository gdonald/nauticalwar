# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::EnemiesController do
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:json) { response.parsed_body }

  describe 'POST #create' do
    it 'creates a enemy, returns enemy id' do
      post :create, params: { id: player_two.id },
                    session: { player_id: player_one.id }
      expect(json['status']).to eq(player_two.id)
    end
  end
end
