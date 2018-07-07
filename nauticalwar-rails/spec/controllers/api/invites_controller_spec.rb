# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::InvitesController do # rubocop:disable /BlockLength, Metrics/
  let(:player_one) { create(:player, :confirmed) }
  let(:player_two) { create(:player, :confirmed) }
  let(:json) { response.parsed_body }

  describe 'GET #index' do
    let!(:invite) { create(:invite, player1: player_one, player2: player_two) }

    it 'returns invites' do
      get :index, params: {}, session: { player_id: player_one.id }
      expected = [{ 'id' => invite.id,
                    'player1_id' => player_one.id,
                    'player1_name' => player_one.name,
                    'player1_rating' => 1200,
                    'player2_id' => player_two.id,
                    'player2_name' => player_two.name,
                    'player2_rating' => 1200,
                    'created_at' => invite.created_at.iso8601,
                    'rated' => '1',
                    'shots_per_turn' => 1,
                    'time_limit' => 86_400,
                    'game_id' => nil }]
      expect(json).to eq(expected)
    end
  end

  describe 'GET #count' do
    let(:invite) { create(:invite, player1: player_one, player2: player_two) }

    before { invite }

    it 'returns invites' do
      get :count, params: {}, session: { player_id: player_one.id }
      expect(json['count']).to eq(1)
    end
  end

  describe 'POST #create' do
    let(:invite) { Invite.last }

    it 'creates an invite' do
      expect do
        post :create, params: { id: player_two.id, r: '1', s: '1', t: '86400' },
                      session: { player_id: player_one.id }
      end.to change(Invite, :count).by(1)
      expected = { 'id' => invite.id,
                   'player1_id' => player_one.id,
                   'player1_name' => player_one.name,
                   'player1_rating' => 1200,
                   'player2_id' => player_two.id,
                   'player2_name' => player_two.name,
                   'player2_rating' => 1200,
                   'created_at' => invite.created_at.iso8601,
                   'rated' => '1',
                   'shots_per_turn' => 1,
                   'time_limit' => 86_400,
                   'game_id' => nil }
      expect(json).to eq(expected)
    end

    it 'fails to create an invite when player not found' do
      expect do
        post :create, params: { id: 0, r: '1', s: '1', t: '86400' },
                      session: { player_id: player_one.id }
      end.not_to change(Invite, :count)
      expect(json['errors']).to eq('An error occured')
    end
  end

  describe 'POST #accept' do
    let(:invite) { create(:invite, player1: player_two, player2: player_one) }
    let(:invite_id) { invite.id.to_s }
    let(:game) { Game.last }

    it 'accepts an invite' do
      expect do
        post :accept, params: { id: invite_id },
                      session: { player_id: player_one.id }
      end.to change(Game, :count).by(1)
      expect(json['game']['id']).to eq(game.id)
      expect(json['game']['player1_id']).to eq(game.player1_id)
      expect(json['game']['player2_id']).to eq(game.player2_id)
      expect(json['game']['player1_name']).to eq(player_two.name)
      expect(json['game']['player2_name']).to eq(player_one.name)
      expect(json['game']['turn_id']).to eq(player_two.id)
      expect(json['game']['winner']).to eq(game.winner)
      expect(json['game']['updated_at']).to eq(game.updated_at.iso8601)
      expect(json['game']['player1_layed_out']).to eq('0')
      expect(json['game']['player2_layed_out']).to eq('0')
      expect(json['game']['rated']).to eq('1')
      expect(json['game']['shots_per_turn']).to eq(1)
      expect(json['game']['t_limit']).to eq(game.t_limit)
      expect(json['invite_id']).to eq(invite_id)
      expect(json['player']['id']).to eq(player_two.id)
      expect(json['player']['name']).to eq(player_two.name)
      expect(json['player']['wins']).to eq(0)
      expect(json['player']['losses']).to eq(0)
      expect(json['player']['rating']).to eq(1200)
      expect(json['player']['last']).to eq(0)
      expect(Invite.find_by(id: invite_id)).to be_nil
    end

    it 'fails to accept an invite' do
      expect do
        post :accept, params: { id: 0 }, session: { player_id: player_one.id }
      end.not_to change(Game, :count)
      expect(json['error']).to eq('Invite not accepted')
      expect(Invite.find_by(id: invite_id)).to be_present
    end
  end

  describe 'POST #decline' do
    let(:invite) { create(:invite, player1: player_two, player2: player_one) }
    let(:invite_id) { invite.id }

    it 'declines an invite' do
      expect do
        post :decline, params: { id: invite_id },
                       session: { player_id: player_one.id }
      end.not_to change(Game, :count)
      expect(json['id']).to eq(invite_id)
      expect(Invite.find_by(id: invite_id)).to be_nil
    end

    it 'fails to decline an invite' do
      expect do
        post :decline, params: { id: 0 }, session: { player_id: player_one.id }
      end.not_to change(Game, :count)
      expect(json['error']).to eq('Invite not found')
      expect(Invite.find_by(id: invite_id)).to be_present
    end
  end

  describe 'POST #cancel' do
    let(:invite) { create(:invite, player1: player_one, player2: player_two) }
    let(:invite_id) { invite.id }

    it 'declines an invite' do
      expect do
        post :cancel, params: { id: invite_id },
                      session: { player_id: player_one.id }
      end.not_to change(Game, :count)
      expect(json['id']).to eq(invite_id)
      expect(Invite.find_by(id: invite_id)).to be_nil
    end

    it 'fails to decline an invite' do
      expect do
        post :cancel, params: { id: 0 }, session: { player_id: player_one.id }
      end.not_to change(Game, :count)
      expect(json['error']).to eq('Invite not found')
      expect(Invite.find_by(id: invite_id)).to be_present
    end
  end
end
