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

  describe 'POST #create' do
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

  describe 'POST #accept' do # rubocop:disable Metrics/BlockLength
    let(:invite) { create(:invite, player_1: player_2, player_2: player_1) }
    let(:invite_id) { invite.id.to_s }
    let(:game) { Game.last }

    it 'accepts an invite' do
      expect do
        post :accept, params: { id: invite_id }
      end.to change(Game, :count).by(1)
      expect(json['game']['id']).to eq(game.id)
      expect(json['game']['player_1_id']).to eq(game.player_1_id)
      expect(json['game']['player_2_id']).to eq(game.player_2_id)
      expect(json['game']['player_1_name']).to eq(player_2.name)
      expect(json['game']['player_2_name']).to eq(player_1.name)
      expect(json['game']['turn_id']).to eq(player_2.id)
      expect(json['game']['winner']).to eq(game.winner)
      expect(json['game']['updated_at']).to eq(game.updated_at.iso8601)
      expect(json['game']['player_1_layed_out']).to eq('0')
      expect(json['game']['player_2_layed_out']).to eq('0')
      expect(json['game']['rated']).to eq('1')
      expect(json['game']['five_shot']).to eq('1')
      expect(json['game']['t_limit']).to eq(game.t_limit)
      expect(json['invite_id']).to eq(invite_id)
      expect(json['player']['id']).to eq(player_2.id)
      expect(json['player']['name']).to eq(player_2.name)
      expect(json['player']['wins']).to eq(0)
      expect(json['player']['losses']).to eq(0)
      expect(json['player']['rating']).to eq(1200)
      expect(json['player']['last']).to eq(0)
      expect(Invite.find_by(id: invite_id)).to be_nil
    end

    it 'fails to accept an invite' do
      expect do
        post :accept, params: { id: 0 }
      end.to change(Game, :count).by(0)
      expect(json['error']).to eq('Invite not accepted')
      expect(Invite.find_by(id: invite_id)).to be
    end
  end

  describe 'POST #decline' do
    let(:invite) { create(:invite, player_1: player_2, player_2: player_1) }
    let(:invite_id) { invite.id }

    it 'declines an invite' do
      expect do
        post :decline, params: { id: invite_id }
      end.to change(Game, :count).by(0)
      expect(json['id']).to eq(invite_id)
      expect(Invite.find_by(id: invite_id)).to be_nil
    end

    it 'fails to decline an invite' do
      expect do
        post :decline, params: { id: 0 }
      end.to change(Game, :count).by(0)
      expect(json['error']).to eq('Invite not found')
      expect(Invite.find_by(id: invite_id)).to be
    end
  end

  describe 'POST #cancel' do
    let(:invite) { create(:invite, player_1: player_1, player_2: player_2) }
    let(:invite_id) { invite.id }

    it 'declines an invite' do
      expect do
        post :cancel, params: { id: invite_id }
      end.to change(Game, :count).by(0)
      expect(json['id']).to eq(invite_id)
      expect(Invite.find_by(id: invite_id)).to be_nil
    end

    it 'fails to decline an invite' do
      expect do
        post :cancel, params: { id: 0 }
      end.to change(Game, :count).by(0)
      expect(json['error']).to eq('Invite not found')
      expect(Invite.find_by(id: invite_id)).to be
    end
  end
end
