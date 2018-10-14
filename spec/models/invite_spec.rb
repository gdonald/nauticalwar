# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invite, type: :model do
  describe '#cannot_invite_self' do
    let(:player) { create(:player) }
    let(:invite) { build(:invite, player_1: player, player_2: player) }

    it 'adds an error' do
      expect(invite).to be_invalid
      expect(invite.errors['player_2']).to be_present
    end
  end

  describe '#create_game' do
    let(:player_1) { create(:player) }
    let(:player_2) { create(:player) }
    let(:invite) { build(:invite, player_1: player_1, player_2: player_2) }

    it 'returns a game' do
      game = invite.create_game
      expect(game.class).to eq(Game)
      expect(game).to be_valid
    end
  end
end
