# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player, type: :model do # rubocop:disable Metrics/BlockLength
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player) }
  let(:player_3) { create(:player) }
  let(:bot) { create(:player, :bot) }

  describe '#to_s' do
    it 'returns a string' do
      expect(player_1.to_s).to eq(player_1.name)
    end
  end

  describe '#find_game' do # rubocop:disable Metrics/BlockLength
    describe 'player' do
      describe 'game exists' do
        let(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_2)
        end
        let(:layout) do
          create(:layout, game: game, player: player_1, ship: create(:ship),
                          x: 3, y: 5)
        end
        let!(:move) do
          create(:move, game: game, player: player_2, x: 3, y: 5,
                        layout: layout)
        end

        it 'returns a game hash' do
          expected = { game: game, layouts: [layout], moves: [move] }
          expect(player_1.find_game(game.id)).to eq(expected)
        end
      end

      it 'returns nil' do
        expect(player_1.find_game(0)).to be_nil
      end
    end

    describe 'opponent' do
      describe 'game exists' do
        let(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_2)
        end
        let(:layout) do
          create(:layout, game: game, player: player_2, ship: create(:ship),
                          x: 3, y: 5)
        end
        let!(:move) do
          create(:move, game: game, player: player_1, x: 3, y: 5,
                        layout: layout)
        end

        it 'returns a game hash' do
          expected = { game: game, layouts: [layout], moves: [move] }
          expect(player_1.find_game(game.id, true)).to eq(expected)
        end
      end

      it 'returns nil' do
        expect(player_1.find_game(0, true)).to be_nil
      end
    end
  end

  describe '#my_turn' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end

    it 'returns true' do
      expect(player_1.my_turn(game.id)).to eq(1)
    end

    it 'returns false' do
      expect(player_2.my_turn(game.id)).to eq(-1)
    end
  end

  describe '#cancel_game!' do # rubocop:disable Metrics/BlockLength
    it 'returns nil when game is not found' do
      expect(player_1.cancel_game!(nil)).to be_nil
    end

    describe 'with enough time' do
      let!(:game) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2)
      end

      it 'player_1 gives up, player_2 wins' do
        result = player_1.cancel_game!(game.id)
        expect(result).to eq(game)
        expect(result.winner).to eq(player_2)
        expect(result.player_1.rating).to eq(1199)
        expect(result.player_2.rating).to eq(1201)
      end

      it 'player_2 gives up, player_1 wins' do
        result = player_2.cancel_game!(game.id)
        expect(result).to eq(game)
        expect(result.winner).to eq(player_1)
        expect(result.player_1.rating).to eq(1201)
        expect(result.player_2.rating).to eq(1199)
      end
    end

    describe 'time has expired' do # rubocop:disable Metrics/BlockLength
      describe 'player_2 has not layed out' do
        let!(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                        player_1_layed_out: true, player_2_layed_out: false)
        end

        it 'player_1 cancels, player_1 wins' do
          travel_to(2.days.from_now) do
            result = player_1.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_1)
            expect(result.player_1.rating).to eq(1201)
            expect(result.player_2.rating).to eq(1199)
          end
        end

        it 'player_2 cancels, player_1 wins' do
          travel_to(2.days.from_now) do
            result = player_2.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_1)
            expect(result.player_1.rating).to eq(1201)
            expect(result.player_2.rating).to eq(1199)
          end
        end
      end

      describe 'player_1 has not layed out' do
        let!(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                        player_1_layed_out: false, player_2_layed_out: true)
        end

        it 'player_2 cancels, player_2 wins' do
          travel_to(2.days.from_now) do
            result = player_2.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_2)
            expect(result.player_1.rating).to eq(1199)
            expect(result.player_2.rating).to eq(1201)
          end
        end

        it 'player_1 cancels, player_2 wins' do
          travel_to(2.days.from_now) do
            result = player_1.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_2)
            expect(result.player_1.rating).to eq(1199)
            expect(result.player_2.rating).to eq(1201)
          end
        end
      end

      describe 'player_1 gives up on player_1 turn' do
        let!(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                        player_1_layed_out: true, player_2_layed_out: true)
        end

        it 'player_2 wins' do
          travel_to(2.days.from_now) do
            result = player_1.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_2)
            expect(result.player_1.rating).to eq(1199)
            expect(result.player_2.rating).to eq(1201)
          end
        end
      end

      describe 'player_1 gives up on player_2 turn' do
        let!(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                        player_1_layed_out: true, player_2_layed_out: true)
        end

        it 'player_1 wins' do
          travel_to(2.days.from_now) do
            result = player_1.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_1)
            expect(result.player_1.rating).to eq(1201)
            expect(result.player_2.rating).to eq(1199)
          end
        end
      end

      describe 'player_2 gives up on player_2 turn' do
        let!(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                        player_1_layed_out: true, player_2_layed_out: true)
        end

        it 'player_1 wins' do
          travel_to(2.days.from_now) do
            result = player_2.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_1)
            expect(result.player_1.rating).to eq(1201)
            expect(result.player_2.rating).to eq(1199)
          end
        end
      end

      describe 'player_2 gives up on player_1 turn' do
        let!(:game) do
          create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                        player_1_layed_out: true, player_2_layed_out: true)
        end

        it 'player_2 wins' do
          travel_to(2.days.from_now) do
            result = player_2.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_2)
            expect(result.player_1.rating).to eq(1199)
            expect(result.player_2.rating).to eq(1201)
          end
        end
      end
    end
  end

  describe '#destroy_game!' do # rubocop:disable Metrics/BlockLength
    it 'returns nil when game is not found' do
      expect(player_1.destroy_game!(nil)).to be_nil
    end

    describe 'with no winner' do
      let!(:game) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2)
      end

      it 'fails to set player_1 deleted' do
        expect do
          result = player_1.destroy_game!(game.id)
          expect(result.del_player_1).to be_falsey
        end.to change(Game, :count).by(0)
      end
    end

    describe 'with a winner' do # rubocop:disable Metrics/BlockLength
      let!(:game) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                      winner: player_1)
      end

      it 'sets player_1 deleted' do
        expect do
          result = player_1.destroy_game!(game.id)
          expect(result.del_player_1).to be_truthy
        end.to change(Game, :count).by(0)
      end

      it 'sets player_2 deleted' do
        expect do
          result = player_2.destroy_game!(game.id)
          expect(result.del_player_2).to be_truthy
        end.to change(Game, :count).by(0)
      end

      it 'deletes game player_2 already deleted' do
        game.update_attributes(del_player_2: true)
        expect do
          player_1.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end

      it 'deletes game player_1 already deleted' do
        game.update_attributes(del_player_1: true)
        expect do
          player_2.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end
    end

    describe 'bot game' do
      let!(:game) do
        create(:game, player_1: player_1, player_2: bot, turn: player_2,
                      winner: player_1)
      end

      it 'deletes the game' do
        expect do
          player_1.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end
    end
  end

  describe '#skip_game!' do
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_2)
    end

    it 'skips inactive opponent' do
      travel_to(2.days.from_now) do
        result = player_1.skip_game!(game.id)
        expect(result).to eq(game)
        expect(result.turn).to eq(player_1)
      end
    end
  end

  describe '#can_skip?' do # rubocop:disable Metrics/BlockLength
    let!(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end

    it 'returns false when game is null' do
      expect(player_1.can_skip?(nil)).to be_falsey
    end

    it 'returns false when time limit is not up' do
      expect(player_1.can_skip?(game)).to be_falsey
    end

    it 'returns false if player turn' do
      travel_to(2.days.from_now) do
        expect(player_1.can_skip?(game)).to be_falsey
      end
    end

    it 'returns false if winner' do
      game.update_attributes(turn: player_2, winner: player_1)
      travel_to(2.days.from_now) do
        expect(player_1.can_skip?(game)).to be_falsey
      end
    end

    it 'returns true if opponent turn' do
      game.update_attributes(turn: player_2)
      travel_to(2.days.from_now) do
        expect(player_1.can_skip?(game)).to be_truthy
      end
    end
  end

  describe '#next_game' do # rubocop:disable Metrics/BlockLength
    describe 'with no player turn games' do
      let!(:game_1) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                      player_1_layed_out: true, player_2_layed_out: true)
      end
      let!(:game_2) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                      player_1_layed_out: true, player_2_layed_out: true)
      end

      it 'returns recent opponent turn game with no time left' do
        travel_to(2.days.from_now) do
          expect(player_1.next_game).to eq(game_2)
        end
      end
    end

    describe 'with player turn games' do
      let!(:game_1) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                      player_1_layed_out: true, player_2_layed_out: true)
      end
      let!(:game_2) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                      player_1_layed_out: true, player_2_layed_out: true)
      end
      let!(:game_3) do
        create(:game, player_1: player_1, player_2: player_2, turn: player_2,
                      player_1_layed_out: true, player_2_layed_out: true)
      end

      it 'returns recent player turn game' do
        expect(player_1.next_game).to eq(game_2)
      end
    end

    describe 'with no games' do
      it 'returns nil' do
        expect(player_1.next_game).to be_nil
      end
    end
  end

  describe '#layed_out_and_no_winner' do
    let!(:game_1) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                    player_1_layed_out: true)
    end
    let!(:game_2) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                    player_1_layed_out: false)
    end
    let!(:game_3) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                    player_1_layed_out: true, player_2_layed_out: true,
                    winner: player_1)
    end
    let!(:game_4) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1,
                    player_1_layed_out: true, player_2_layed_out: true)
    end

    it 'returns layed out games with no winner' do
      expect(player_1.layed_out_and_no_winner).to eq([game_4])
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
