# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::InvitesController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  let(:player_1) { create(:player, :confirmed) }
  let(:player_2) { create(:player, :confirmed) }
  let(:json) { JSON.parse(response.body) }

  before do
    login(player_1)
  end

  describe 'GET #index' do
    let!(:invite) { create(:invite, player_1: player_1, player_2: player_2) }

    it 'returns invites' do
      get :index
      expected = [{ 'id' => invite.id,
                    'player_1_id' => player_1.id,
                    'player_2_id' => player_2.id,
                    'created_at' => invite.created_at.iso8601,
                    'rated' => '1',
                    'five_shot' => '1',
                    'time_limit' => 86_400,
                    'game_id' => nil }]
      expect(json).to eq(expected)
    end
  end

  describe 'GET #count' do
    let!(:invite) { create(:invite, player_1: player_1, player_2: player_2) }

    it 'returns invites' do
      get :count
      expect(json['count']).to eq(1)
    end
  end

  describe 'GET #create' do
    let(:invite) { Invite.last }

    it 'creates an invite' do
      expect do
        post :create, params: { id: player_2.id, r: '1', m: '0', t: '0' }
      end.to change(Invite, :count).by(1)
      expected = { 'id' => invite.id,
                   'player_1_id' => player_1.id,
                   'player_2_id' => player_2.id,
                   'created_at' => invite.created_at.iso8601,
                   'rated' => '1',
                   'five_shot' => '1',
                   'time_limit' => 86_400,
                   'game_id' => nil }
      expect(json).to eq(expected)
    end

    it 'fails to create an invite when player not found' do
      expect do
        post :create, params: { id: 0, r: '1', m: '0', t: '0' }
      end.to change(Invite, :count).by(0)
      expect(json['errors']).to eq('An error occured')
    end
  end
end
