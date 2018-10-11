# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invite, type: :model do
  describe '#cannot_invite_self' do
    let(:user) { create(:user) }
    let(:invite) { build(:invite, user_1: user, user_2: user) }

    it 'adds an error' do
      expect(invite).to be_invalid
      expect(invite.errors['user_2']).to be_present
    end
  end

  describe '#create_game' do
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }
    let(:invite) { build(:invite, user_1: user_1, user_2: user_2) }

    it 'returns a game' do
      game = invite.create_game
      expect(game.class).to eq(Game)
      expect(game).to be_valid
    end
  end
end
