# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invite do
  describe '#cannot_invite_self' do
    let(:player) { create(:player) }
    let(:invite) { build(:invite, player1: player, player2: player) }

    it 'adds an error' do
      expect(invite).not_to be_valid
      expect(invite.errors['player2']).to be_present
    end
  end

  describe '#create_game' do
    let(:player_one) { create(:player) }
    let(:player_two) { create(:player) }
    let(:invite) { build(:invite, player1: player_one, player2: player_two) }

    it 'returns a game' do
      game = invite.create_game
      expect(game.class).to eq(Game)
      expect(game).to be_valid
    end
  end

  describe '.shot_opts' do
    it 'returns an array of shot options' do
      expect(described_class.shot_opts).to eq([5, 4, 3, 2, 1])
    end
  end

  describe '.time_limits' do
    it 'returns a hash of time limits' do
      expected = { '86400': '1 day',
                   '28800': '8 hours',
                   '3600': '1 hour',
                   '900': '15 minutes',
                   '300': '5 minutes' }
      expect(described_class.time_limits).to eq(expected)
    end
  end
end
