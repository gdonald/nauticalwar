# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player, type: :model do
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:player_3) { create(:player) }

  describe '#active_games' do
    let!(:game_1) { create(:game, player_1: player_1, player_2: player_2, turn: player_1) }
    let!(:game_2) { create(:game, player_1: player_2, player_2: player_1, turn: player_1, del_player_1: true) }
    let!(:game_3) { create(:game, player_1: player_3, player_2: player_1, turn: player_1, del_player_2: true) }

    it 'returns active games' do
      expect(player_1.active_games).to eq([game_1, game_2])
    end
  end

  describe '#invites' do
    let!(:invite_1) { create(:invite, player_1: player_1, player_2: player_2) }
    let!(:invite_2) { create(:invite, player_1: player_2, player_2: player_1) }
    let!(:invite_3) { create(:invite, player_1: player_2, player_2: player_3) }

    it 'returns invites' do
      expect(player_1.invites).to eq([invite_1, invite_2])
    end
  end
end
