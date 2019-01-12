# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player, type: :model do # rubocop:disable Metrics/BlockLength
  let(:player_1) { create(:player) }
  let(:player_2) { create(:player, :confirmed) }
  let(:player_3) { create(:player) }
  let(:bot) { create(:player, :bot) }

  describe '#to_s' do
    it 'returns a string' do
      expect(player_1.to_s).to eq(player_1.name)
    end
  end

  describe '.reset_password' do # rubocop:disable Metrics/BlockLength
    describe 'cannot find a player' do
      it 'with the wrong token' do
        result = Player.reset_password(token: 'foo')
        expect(result).to eq(id: -1)
      end
    end

    describe 'finds a player' do
      let(:params) do
        { token: player_1.password_token, password: 'foo',
          password_confirmation: 'foo' }
      end

      before do
        player_1.reset_password_token
      end

      it 'finds a player with an expired token' do
        travel_to 2.hours.from_now do
          result = Player.reset_password(params)
          expect(result).to eq(id: -2)
        end
      end

      it 'cannot update with different passwords' do
        params[:password] = 'bar'
        result = Player.reset_password(params)
        expect(result).to eq(id: -3)
      end

      it 'updates a player password' do
        result = Player.reset_password(params)
        expect(result).to eq(id: player_1.id)
      end
    end
  end

  describe '.locate_account' do
    let(:params) { { email: player_1.email } }

    it 'finds a player' do
      result = Player.locate_account(params)
      expect(result).to eq(id: player_1.id)
    end

    it 'fails to find a player' do
      result = Player.locate_account(email: 'foo@bar.com')
      expect(result).to eq(id: -1)
    end
  end

  describe '.authenticate' do
    let(:result) { Player.authenticate(params) }

    describe 'unknown email' do
      let(:params) { { email: 'unknown@example.com' } }

      it 'does not find a player' do
        expect(result).to eq(error: 'Player not found')
      end
    end

    describe 'wrong password' do
      let(:params) { { email: player_2.email, password: 'wrong' } }

      it 'does not authenticate a player' do
        expect(result).to eq(error: 'Login failed')
      end
    end

    describe 'valid params' do
      let(:params) { { email: player_2.email, password: 'changeme' } }

      before do
        player_2.update_attributes(last_sign_in_at: nil)
      end

      it 'authenticates a player' do
        expect(player_2.last_sign_in_at).to_not be
        expect(result).to eq(id: player_2.id)
        player_2.reload
        expect(player_2.last_sign_in_at).to be
      end
    end
  end

  describe '.authenticate_admin' do
    let!(:admin) { create(:player, :admin) }
    let(:result) { Player.authenticate_admin(params) }

    describe 'unknown email' do
      let(:params) { { email: 'unknown@example.com' } }

      it 'does not find a player' do
        expect(result).to eq(error: 'Admin not found')
      end
    end

    describe 'wrong password' do
      let(:params) { { email: admin.email, password: 'wrong' } }

      it 'does not authenticate a player' do
        expect(result).to eq(error: 'Login failed')
      end
    end

    describe 'valid params' do
      let(:params) { { email: admin.email, password: 'changeme' } }

      it 'authenticates a player' do
        expect(result).to eq(id: Player.last.id)
      end
    end
  end

  describe '.confirm_email' do
    it 'updates confirmed at' do
      Player.confirm_email(player_1.confirmation_token)
      player_1.reload
      expect(player_1.confirmed_at).to be
    end
  end

  describe '.create_player' do # rubocop:disable Metrics/BlockLength
    let(:player) { Player.last }
    let(:response) { Player.create_player(params) }

    describe 'with valid params' do
      let(:params) do
        { email: 'foo@bar.com',
          name: 'foo',
          password: 'changeme',
          password_confirmation: 'changeme' }
      end

      it 'creates a player' do
        expect do
          expect(response[:id]).to eq(player.id)
        end.to change(Player, :count).by(1)
      end
    end

    describe 'with invalid params' do
      let(:params) { {} }
      let(:blank) { ["can't be blank"] }
      let(:invalid) { ["can't be blank", 'is not valid'] }

      it 'returns errors' do
        expect do
          expect(response[:errors][:email]).to eq(invalid)
          expect(response[:errors][:name]).to eq(blank)
          expect(response[:errors][:password]).to eq(blank)
          expect(response[:errors][:password_confirmation]).to eq(blank)
        end.to change(Player, :count).by(0)
      end
    end
  end

  describe '.params_with_password' do
    let(:params) { { foo: 'bar' } }

    it 'adds a random password' do
      results = Player.params_with_password(params)
      expect(results[:foo]).to eq('bar')
      expect(results[:password]).to be
      expect(results[:password_confirmation]).to be
      expect(results[:password]).to eq(results[:password_confirmation])
    end
  end

  describe '.complete_google_signup' do # rubocop:disable Metrics/BlockLength
    let(:player) { Player.last }
    let(:response) { Player.complete_google_signup(params) }

    describe 'with valid params' do
      let(:params) do
        { email: 'foo@bar.com',
          name: 'foo' }
      end

      it 'creates a player' do
        expect do
          expect(response[:id]).to eq(player.id)
        end.to change(Player, :count).by(1)
      end
    end

    describe 'with invalid params' do
      let(:params) { {} }
      let(:blank) { ["can't be blank"] }
      let(:invalid) { ["can't be blank", 'is not valid'] }

      it 'returns errors' do
        expect do
          expect(response[:errors][:email]).to eq(invalid)
          expect(response[:errors][:name]).to eq(blank)
          expect(response[:errors][:password]).to eq([])
          expect(response[:errors][:password_confirmation]).to eq([])
        end.to change(Player, :count).by(0)
      end
    end
  end

  describe '#admin?' do
    let(:player) { create(:player) }

    it 'returns false' do
      expect(player.admin?).to be_falsey
    end

    it 'returns true' do
      player.admin = true
      expect(player.admin?).to be_truthy
    end
  end

  describe '#cancel_invite!' do
    let(:invite) { create(:invite, player_1: player_1, player_2: player_2) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player_1.cancel_invite!(id)
      end.to change(Game, :count).by(0)
      expect(Invite.find_by(id: id)).to be_nil
    end
  end

  describe '#decline_invite!' do
    let(:invite) { create(:invite, player_1: player_1, player_2: player_2) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player_2.decline_invite!(id)
      end.to change(Game, :count).by(0)
      expect(Invite.find_by(id: id)).to be_nil
    end
  end

  describe '#accept_invite!' do
    let(:invite) { create(:invite, player_1: player_1, player_2: player_2) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player_2.accept_invite!(id)
      end.to change(Game, :count).by(1)
      expect(Invite.find_by(id: id)).to be_nil
    end
  end

  describe '#create_invite!' do
    let(:params) { { id: 0, r: '1', m: '0', t: '0' } }

    it 'fails to create an invite' do
      expect do
        player_1.create_invite!(params)
      end.to change(Invite, :count).by(0)
    end

    it 'creates an invite' do
      params[:id] = player_2.id
      expect do
        player_1.create_invite!(params)
      end.to change(Invite, :count).by(1)
    end

    it 'creates a game' do
      params[:id] = bot.id
      expect do
        player_1.create_invite!(params)
      end.to change(Game, :count).by(1)
    end
  end

  describe '#create_bot_game!' do
    let(:args) do
      { player_2: bot,
        rated: true,
        five_shot: true,
        time_limit: 86_400 }
    end

    it 'creates a bot game' do
      expect do
        game = player_1.create_bot_game!(args)
        expect(game.player_1).to eq(player_1)
        expect(game.player_2).to eq(bot)
        expect(game.rated).to be_truthy
        expect(game.five_shot).to be_truthy
        expect(game.time_limit).to eq(86_400)
      end.to change(Game, :count).by(1)
    end
  end

  describe '#create_opponent_invite!' do
    let(:args) do
      { player_2: player_2,
        rated: true,
        five_shot: true,
        time_limit: 86_400 }
    end

    it 'creates an opponent invite' do
      expect do
        invite = player_1.create_opponent_invite!(args)
        expect(invite.player_1).to eq(player_1)
        expect(invite.player_2).to eq(player_2)
        expect(invite.rated).to be_truthy
        expect(invite.five_shot).to be_truthy
        expect(invite.time_limit).to eq(86_400)
      end.to change(Invite, :count).by(1)
    end
  end

  describe '#invite_args' do
    let(:params) { { id: player_2.id, r: '1', m: '0', t: '0' } }

    it 'returns a hash of invite args' do
      args = player_1.invite_args(params)
      expect(args[:player_2]).to eq(player_2)
      expect(args[:rated]).to be_truthy
      expect(args[:five_shot]).to be_truthy
      expect(args[:time_limit]).to eq(86_400)
    end
  end

  describe '#create_enemy!' do
    let(:player) { create(:player, :confirmed) }

    it 'creates a enemy' do
      expect do
        player_1.create_enemy!(player.id)
      end.to change(Enemy, :count).by(1)
      expect(player_1.enemies.first.player_2).to eq(player)
    end

    describe 'fails to create a enemy' do
      it 'when player not found' do
        expect do
          result = player_1.create_enemy!(0)
          expect(result).to eq(-1)
        end.to change(Enemy, :count).by(0)
      end

      describe 'fails to add enemy' do
        let(:friend) { create(:friend, player_1: player_1, player_2: player_2) }

        it 'when already a friend' do
          expect do
            result = player_1.create_enemy!(friend.id)
            expect(result).to eq(-1)
          end.to change(Enemy, :count).by(0)
        end
      end
    end
  end

  describe '#enemy_ids' do
    let!(:enemy_1) { create(:enemy, player_1: player_1, player_2: player_2) }
    let!(:enemy_2) { create(:enemy, player_1: player_2, player_2: player_3) }
    let!(:enemy_3) { create(:enemy, player_1: player_2, player_2: player_1) }

    it 'returns enemy ids' do
      expect(Enemy.count).to eq(3)
      expect(player_1.enemies_player_ids).to eq([player_2.id])
    end
  end

  describe '#destroy_friend!' do
    let!(:friend) { create(:friend, player_1: player_1, player_2: player_2) }

    it 'destroys a friend' do
      expect do
        player_1.destroy_friend!(player_2.id)
      end.to change(Friend, :count).by(-1)
      expect(player_1.friends).to eq([])
    end

    it 'fails to destroy a friend' do
      expect do
        result = player_1.destroy_friend!(0)
        expect(result).to eq(-1)
      end.to change(Friend, :count).by(0)
    end
  end

  describe '#create_friend!' do
    let(:player) { create(:player, :confirmed) }

    it 'creates a friend' do
      expect do
        player_1.create_friend!(player.id)
      end.to change(Friend, :count).by(1)
      expect(player_1.friends.first.player_2).to eq(player)
    end

    describe 'fails to create a friend' do
      it 'when other player not found' do
        expect do
          result = player_1.create_friend!(0)
          expect(result).to eq(-1)
        end.to change(Friend, :count).by(0)
      end

      describe 'fails to add a friend' do
        let(:enemy) { create(:enemy, player_1: player_1, player_2: player_2) }

        it 'when already an enemy' do
          expect do
            result = player_1.create_friend!(enemy.id)
            expect(result).to eq(-1)
          end.to change(Friend, :count).by(0)
        end
      end
    end
  end

  describe '#friend_ids' do
    let!(:friend_1) { create(:friend, player_1: player_1, player_2: player_2) }
    let!(:friend_2) { create(:friend, player_1: player_2, player_2: player_3) }
    let!(:friend_3) { create(:friend, player_1: player_2, player_2: player_1) }

    it 'returns friend ids' do
      expect(Friend.count).to eq(3)
      expect(player_1.friends_player_ids).to eq([player_2.id])
    end
  end

  describe '#attack!' do # rubocop:disable Metrics/BlockLength
    let(:game) do
      create(:game, player_1: player_1, player_2: bot, turn: player_1)
    end
    let(:ship) { create(:ship, size: 3) }
    let!(:layout_1) do
      create(:layout, game: game, player: player_1, ship: ship, x: 0, y: 0)
    end
    let!(:layout_2) do
      create(:layout, game: game, player: player_1, ship: ship, x: 1, y: 1)
    end
    let!(:layout_3) do
      create(:layout, game: game, player: player_1, ship: ship, x: 2, y: 2)
    end
    let!(:layout_4) do
      create(:layout, game: game, player: player_1, ship: ship, x: 3, y: 3)
    end
    let!(:layout_5) do
      create(:layout, game: game, player: player_1, ship: ship, x: 4, y: 4)
    end
    let!(:layout) do
      create(:layout, game: game, player: bot, ship: ship, x: 0, y: 0)
    end
    let(:json) do
      [{ 'x': 5, 'y': 5 },
       { 'x': 4, 'y': 6 },
       { 'x': 6, 'y': 6 },
       { 'x': 3, 'y': 7 },
       { 'x': 2, 'y': 8 }].to_json
    end
    let(:params) { { s: json } }

    it 'saves an attack' do
      expect do
        player_1.attack!(game, params)
      end.to change(Move, :count).by(10)
      expect(game.winner).to be_nil
      expect(game.turn).to eq(player_1)
    end
  end

  describe '#record_shots!' do
    let(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end
    let(:json) do
      [{ 'x': 5, 'y': 5 },
       { 'x': 4, 'y': 6 },
       { 'x': 6, 'y': 6 },
       { 'x': 3, 'y': 7 },
       { 'x': 2, 'y': 8 }].to_json
    end

    it 'records shots' do
      expect do
        player_1.record_shots!(game, json)
      end.to change(Move, :count).by(5)
      expect(game.turn).to eq(player_2)
    end
  end

  describe '#record_shot!' do # rubocop:disable Metrics/BlockLength
    let(:game) do
      create(:game, player_1: player_1, player_2: player_2, turn: player_1)
    end
    let!(:layout) do
      create(:layout, game: game, player: player_2, ship: create(:ship),
                      x: 3, y: 5)
    end

    describe 'when shot already exists' do
      let!(:move) do
        create(:move, game: game, player: player_1, x: 3, y: 5,
                      layout: layout)
      end

      it 'does not record a shot' do
        expect do
          player_1.record_shot!(game, 3, 5)
        end.to_not change(Move, :count)
      end
    end

    describe 'when shot does not already exists' do
      it 'records a hit' do
        expect do
          player_1.record_shot!(game, 3, 5)
        end.to change(Move, :count).by(1)
        expect(Move.last.layout).to eq(layout)
      end

      it 'records a miss' do
        expect do
          player_1.record_shot!(game, 5, 6)
        end.to change(Move, :count).by(1)
        expect(Move.last.layout).to be_nil
      end
    end
  end

  describe '#new_activity' do
    it 'increments player activity' do
      expect do
        player_1.new_activity!
      end.to change { player_1.activity }.by(1)
    end
  end

  describe '#player_game' do
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
        expect(player_1.player_game(game.id)).to eq(expected)
      end
    end

    it 'returns nil' do
      expect(player_1.player_game(0)).to be_nil
    end
  end

  describe '#opponent_game' do
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
        expected = { game: game, layouts: [], moves: [move] }
        expect(player_1.opponent_game(game.id)).to eq(expected)
      end
    end

    it 'returns nil' do
      expect(player_1.opponent_game(0)).to be_nil
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

  describe '.list_for_game' do
    let(:game) do
      create(:game, player_1: player_1, player_2: bot, turn: player_1)
    end

    it 'returns game players' do
      expected = [player_1, bot]
      expect(Player.list_for_game(game.id)).to eq(expected)
    end
  end

  describe '.list' do
    let(:player_1) { create(:player, :confirmed) }
    let(:player_2) { create(:player, :confirmed) }
    let(:player_3) { create(:player, :confirmed) }
    let!(:enemy) { create(:enemy, player_1: player_1, player_2: player_2) }

    it 'returns players' do
      expected = [player_1, player_3]
      expect(Player.list(player_1)).to eq(expected)
    end

    describe 'non-confirmed' do
      let!(:player_3) { create(:player) }

      it 'returns players' do
        expected = [player_1]
        expect(Player.list(player_1)).to eq(expected)
      end
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
