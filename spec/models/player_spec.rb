# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player, type: :model do # rubocop:disable Metrics/BlockLength
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:player_3) { create(:player) }

  describe '#to_s' do
    it 'returns a string' do
      expect(player_1.to_s).to eq(player_1.name)
    end
  end

  describe '#active_games' do
    let!(:game_1) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end
    let!(:game_2) do
      create(:game, player_1: player_2, player_2: player_1, turn: player_1,
                    del_player_1: true)
    end
    let!(:game_3) do
      create(:game, player_1: player_3, player_2: player_1, turn: player_1,
                    del_player_2: true)
    end

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

  describe '.list' do
    it 'returns players' do
      expected = [player_1, player_2, player_3]
      expect(Player.list(player_1)).to eq(expected)
    end
  end

  describe '.generate_password' do
    let(:password) { Player.generate_password(16) }

    it 'returns a generated password' do
      expect(password.length).to eq(16)
    end
  end

  describe '#last' do
    let(:player_1) { create(:player, last_sign_in_at: Time.current) }
    let(:player_2) { create(:player, last_sign_in_at: 2.hours.ago) }
    let(:player_3) { create(:player, last_sign_in_at: 2.days.ago) }
    let(:player_4) { create(:player, last_sign_in_at: 4.days.ago) }
    let(:player_5) { create(:player, last_sign_in_at: nil) }
    let(:bot) { create(:player, :bot) }

    it 'signed in recently returns a 0' do
      expect(player_1.last).to eq(0)
    end

    it 'signed in 2 hours ago returns a 1' do
      expect(player_2.last).to eq(1)
    end

    it 'signed in 2 days ago returns a 2' do
      expect(player_3.last).to eq(2)
    end

    it 'signed in 4 days ago returns a 3' do
      expect(player_4.last).to eq(3)
    end

    it 'never logged in returns a 3' do
      expect(player_5.last).to eq(3)
    end

    it 'bot returns a 0' do
      expect(bot.last).to eq(0)
    end
  end
end
