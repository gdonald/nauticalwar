# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player do
  let_it_be(:player4) { create(:player, name: 'player4') }
  let_it_be(:player5) { create(:player, :confirmed, name: 'player5') }

  let(:player1) { build_stubbed(:player, id: 1, name: 'player1') }
  let(:player2) { build_stubbed(:player, :confirmed, id: 2) }
  let(:player3) { build_stubbed(:player, id: 3) }
  let(:bot1) { build_stubbed(:player, :bot, id: 4) }
  let(:bot2) { create(:player, :bot) }
  let(:bot3) { create(:player, :bot) }

  describe '#to_s' do
    it 'returns a string' do
      expect(player1.to_s).to eq(player1.name)
    end
  end

  describe '.reset_password' do
    describe 'cannot find a player' do
      it 'with the wrong token' do
        result = described_class.reset_password(token: 'foo')
        expect(result).to eq(id: -1)
      end
    end

    describe 'finds a player' do
      let(:params) do
        { token: player4.password_token, password: 'foo',
          password_confirmation: 'foo' }
      end

      before do
        player4.reset_password_token
      end

      it 'finds a player with an expired token' do
        travel_to 2.hours.from_now do
          result = described_class.reset_password(params)
          expect(result).to eq(id: -2)
        end
      end

      it 'cannot update with different passwords' do
        params[:password] = 'bar'
        result = described_class.reset_password(params)
        expect(result).to eq(id: -3)
      end

      it 'updates a player password' do
        result = described_class.reset_password(params)
        expect(result).to eq(id: player4.id)
      end
    end
  end

  describe '.locate_account' do
    let(:params) { { email: player4.email } }

    it 'finds a player' do
      result = described_class.locate_account(params)
      expect(result).to eq(id: player4.id)
    end

    it 'fails to find a player' do
      result = described_class.locate_account(email: 'foo@bar.com')
      expect(result).to eq(id: -1)
    end
  end

  describe '.authenticate' do
    let(:result) { described_class.authenticate(params) }

    describe 'unknown email' do
      let(:params) { { email: 'unknown@example.com' } }

      it 'does not find a player' do
        expect(result).to eq(error: 'Player not found')
      end
    end

    describe 'wrong password' do
      let(:params) { { email: player4.email, password: 'wrong' } }

      it 'does not authenticate a confirmed player' do
        player4.update(confirmed_at: Time.zone.now)
        expect(result).to eq(error: 'Login failed')
      end

      it 'does not authenticate an unconfirmed player' do
        expect(result).to eq(error: 'Email not confirmed')
      end
    end

    describe 'valid params' do
      let(:params) { { email: player4.email, password: 'changeme' } }

      before do
        player4.update(last_sign_in_at: nil)
      end

      it 'authenticates a confirmed player' do
        player4.update(confirmed_at: Time.zone.now)
        expect(player4.last_sign_in_at).not_to be_present
        expect(result).to eq(id: player4.id)
        player4.reload
        expect(player4.last_sign_in_at).to be_present
      end

      it 'fails to authenticate an unconfirmed player' do
        expect(player4.last_sign_in_at).not_to be_present
        expect(result).to eq(error: 'Email not confirmed')
        player4.reload
        expect(player4.last_sign_in_at).not_to be_present
      end
    end
  end

  describe '.authenticate_admin' do
    let!(:admin) { create(:player, :admin) }
    let(:result) { described_class.authenticate_admin(params) }

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
        expect(result).to eq(id: described_class.last.id)
      end
    end
  end

  describe '.confirm_email' do
    it 'updates confirmed at' do
      described_class.confirm_email(player4.confirmation_token)
      player4.reload
      expect(player4.confirmed_at).to be_present
    end
  end

  describe '.create_player' do
    let(:player) { described_class.last }
    let(:response) { described_class.create_player(params) }

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
        end.to change(described_class, :count).by(1)
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
        end.not_to change(described_class, :count)
      end
    end
  end

  describe '.params_with_password' do
    let(:params) { { foo: 'bar' } }

    it 'adds a random password' do
      results = described_class.params_with_password(params)
      expect(results[:foo]).to eq('bar')
      expect(results[:password]).to be_present
      expect(results[:password_confirmation]).to be_present
      expect(results[:password]).to eq(results[:password_confirmation])
    end
  end

  describe '.complete_google_signup' do
    let(:player) { described_class.last }
    let(:response) { described_class.complete_google_signup(params) }

    describe 'with valid params' do
      let(:params) do
        { email: 'foo@bar.com',
          name: 'foo' }
      end

      it 'creates a player' do
        expect do
          expect(response[:id]).to eq(player.id)
        end.to change(described_class, :count).by(1)
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
        end.not_to change(described_class, :count)
      end
    end
  end

  describe '#admin?' do
    let(:player) { build_stubbed(:player) }

    it 'returns false' do
      expect(player).not_to be_admin
    end

    it 'returns true' do
      player.admin = true
      expect(player).to be_admin
    end
  end

  describe '#cancel_invite!' do
    let(:invite) { create(:invite, player1:, player2:) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player1.cancel_invite!(id)
      end.not_to change(Game, :count)
      expect(Invite.find_by(id:)).to be_nil
    end
  end

  describe '#decline_invite!' do
    let(:invite) { create(:invite, player1:, player2:) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player2.decline_invite!(id)
      end.not_to change(Game, :count)
      expect(Invite.find_by(id:)).to be_nil
    end
  end

  describe '#accept_invite!' do
    let(:invite) { create(:invite, player1: player4, player2: player5) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player5.accept_invite!(id)
      end.to change(Game, :count).by(1)
      expect(Invite.find_by(id:)).to be_nil
    end
  end

  describe '#create_invite!' do
    let(:params) { { id: 0, r: '1', s: '1', t: '300' } }

    it 'fails to create an invite' do
      expect do
        player1.create_invite!(params)
      end.not_to change(Invite, :count)
    end

    it 'creates an invite' do
      player5.save!
      params[:id] = player5.id
      expect do
        player4.create_invite!(params)
      end.to change(Invite, :count).by(1)
    end

    it 'creates a game' do
      params[:id] = bot2.id
      expect do
        player4.create_invite!(params)
      end.to change(Game, :count).by(1)
    end
  end

  describe '#create_bot_game!' do
    let(:args) do
      { player2: bot2,
        rated: true,
        shots_per_turn: 5,
        time_limit: 86_400 }
    end

    it 'creates a bot game' do
      expect do
        game = player4.create_bot_game!(args)
        expect(game.player1).to eq(player4)
        expect(game.player2).to eq(bot2)
        expect(game.rated).to be_truthy
        expect(game.shots_per_turn).to eq(5)
        expect(game.time_limit).to eq(86_400)
      end.to change(Game, :count).by(1)
    end
  end

  describe '#create_opponent_invite!' do
    let(:args) do
      { player2: player5,
        rated: true,
        shots_per_turn: 5,
        time_limit: 86_400 }
    end

    it 'creates an opponent invite' do
      expect do
        invite = player4.create_opponent_invite!(args)
        expect(invite.player1).to eq(player4)
        expect(invite.player2).to eq(player5)
        expect(invite.rated).to be_truthy
        expect(invite.shots_per_turn).to eq(5)
        expect(invite.time_limit).to eq(86_400)
      end.to change(Invite, :count).by(1)
    end
  end

  describe '#invite_args' do
    let(:params) { { id: player5.id, r: '1', s: '5', t: '86400' } }

    it 'returns a hash of invite args' do
      args = player4.invite_args(params)
      expect(args[:player2]).to eq(player5)
      expect(args[:rated]).to be_truthy
      expect(args[:shots_per_turn]).to eq(5)
      expect(args[:time_limit]).to eq(86_400)
    end
  end

  describe '#create_enemy!' do
    it 'creates a enemy' do
      expect do
        player4.create_enemy!(player5.id)
      end.to change(Enemy, :count).by(1)
      expect(player4.enemies.first.player2).to eq(player5)
    end

    describe 'fails to create a enemy' do
      it 'when player not found' do
        expect do
          result = player4.create_enemy!(0)
          expect(result).to eq(-1)
        end.not_to change(Enemy, :count)
      end

      describe 'fails to add enemy' do
        let(:friend) { create(:friend, player1: player4, player2: player5) }

        before { friend }

        it 'when already a friend' do
          expect do
            result = player4.create_enemy!(player5.id)
            expect(result).to eq(-1)
          end.not_to change(Enemy, :count)
        end
      end
    end
  end

  describe '#enemy_ids' do
    let(:enemy1) { create(:enemy, player1:, player2:) }
    let(:enemy2) { create(:enemy, player1: player2, player2: player3) }
    let(:enemy3) { create(:enemy, player1: player2, player2: player1) }

    before { [enemy1, enemy2, enemy3] }

    it 'returns enemy ids' do
      expect(Enemy.count).to eq(3)
      expect(player1.enemies_player_ids).to eq([player2.id])
    end
  end

  describe '#destroy_friend!' do
    let(:friend) { create(:friend, player1:, player2:) }

    before { friend }

    it 'destroys a friend' do
      expect do
        player1.destroy_friend!(player2.id)
      end.to change(Friend, :count).by(-1)
      expect(player1.friends).to eq([])
    end

    it 'fails to destroy a friend' do
      expect do
        result = player1.destroy_friend!(0)
        expect(result).to eq(-1)
      end.not_to change(Friend, :count)
    end
  end

  describe '#create_friend!' do
    it 'creates a friend' do
      player5.save!
      expect do
        player4.reload.create_friend!(player5.id)
      end.to change(Friend, :count).by(1)
      expect(player4.friends.first.player2).to eq(player5)
    end

    describe 'fails to create a friend' do
      it 'when other player not found' do
        expect do
          result = player4.create_friend!(0)
          expect(result).to eq(-1)
        end.not_to change(Friend, :count)
      end

      describe 'fails to add a friend' do
        let(:enemy) { create(:enemy, player1: player4, player2: player5) }

        before { enemy }

        it 'when already an enemy' do
          expect do
            result = player4.create_friend!(player5.id)
            expect(result).to eq(-1)
          end.not_to change(Friend, :count)
        end
      end
    end
  end

  describe '#friend_ids' do
    let(:friend1) { create(:friend, player1:, player2:) }
    let(:friend2) { create(:friend, player1: player2, player2: player3) }
    let(:friend3) { create(:friend, player1: player2, player2: player1) }

    before { [friend1, friend2, friend3] }

    it 'returns friend ids' do
      expect(Friend.count).to eq(3)
      expect(player1.friends_player_ids).to eq([player2.id])
    end
  end

  describe '#attack!' do
    let(:game) do
      create(:game, shots_per_turn: 5, player1: player4, player2: bot2, turn: player4)
    end
    let(:ship) { create(:ship, size: 3) }
    let(:layout1) do
      create(:layout, game:, player: player4, ship:, x: 0, y: 0)
    end
    let(:layout2) do
      create(:layout, game:, player: player4, ship:, x: 1, y: 1)
    end
    let(:layout3) do
      create(:layout, game:, player: player4, ship:, x: 2, y: 2)
    end
    let(:layout4) do
      create(:layout, game:, player: player4, ship:, x: 3, y: 3)
    end
    let(:layout5) do
      create(:layout, game:, player: player4, ship:, x: 4, y: 4)
    end
    let(:layout) do
      create(:layout, game:, player: bot2, ship:, x: 0, y: 0)
    end
    let(:json) do
      [{ x: 5, y: 5 },
       { x: 4, y: 6 },
       { x: 6, y: 6 },
       { x: 3, y: 7 },
       { x: 2, y: 8 }].to_json
    end
    let(:params) { { s: json } }

    before { [layout, layout1, layout2, layout3, layout4, layout5] }

    it 'saves an attack' do
      expect do
        player4.attack!(game, params)
      end.to change(Move, :count).by(10)
      expect(game.winner).to be_nil
      expect(game.turn).to eq(player4)
    end
  end

  describe '#record_shots!' do
    let(:game) do
      create(:game, shots_per_turn: 5, player1: player4, player2: player5, turn: player4)
    end
    let(:json) do
      [{ x: 5, y: 5 },
       { x: 4, y: 6 },
       { x: 6, y: 6 },
       { x: 3, y: 7 },
       { x: 2, y: 8 }].to_json
    end

    it 'records shots' do
      expect do
        player4.record_shots!(game, json)
      end.to change(Move, :count).by(5)
      expect(game.turn).to eq(player5)
    end
  end

  describe '#record_shot!' do
    let(:game) do
      create(:game, player1: player4, player2: player5, turn: player4)
    end
    let!(:layout) do
      create(:layout, game:, player: player5, ship: create(:ship),
                      x: 3, y: 5)
    end

    describe 'when shot already exists' do
      let(:move) do
        create(:move, game:, player: player4, x: 3, y: 5,
                      layout:)
      end

      before { move }

      it 'does not record a shot' do
        expect do
          player4.record_shot!(game, 3, 5)
        end.not_to change(Move, :count)
      end
    end

    describe 'when shot does not already exists' do
      it 'records a hit' do
        expect do
          player4.record_shot!(game, 3, 5)
        end.to change(Move, :count).by(1)
        expect(Move.last.layout).to eq(layout)
      end

      it 'records a miss' do
        expect do
          player4.record_shot!(game, 5, 6)
        end.to change(Move, :count).by(1)
        expect(Move.last.layout).to be_nil
      end
    end
  end

  describe '#new_activity' do
    it 'increments player activity' do
      expect do
        player4.new_activity!
      end.to change(player4, :activity).by(1)
    end
  end

  describe '#player_game' do
    describe 'game exists' do
      let(:game) do
        create(:game, player1: player4, player2: player5, turn: player5)
      end
      let(:layout) do
        create(:layout, game:, player: player4, ship: create(:ship),
                        x: 3, y: 5)
      end
      let!(:move) do
        create(:move, game:, player: player5, x: 3, y: 5,
                      layout:)
      end

      it 'returns a game hash' do
        expected = { game:, layouts: [layout], moves: [move] }
        expect(player4.player_game(game.id)).to eq(expected)
      end
    end

    it 'returns nil' do
      expect(player4.player_game(0)).to be_nil
    end
  end

  describe '#opponent_game' do
    describe 'game exists' do
      let(:game) do
        create(:game, player1: player4, player2: player5, turn: player5)
      end
      let(:layout) do
        create(:layout, game:, player: player5, ship: create(:ship),
                        x: 3, y: 5)
      end
      let!(:move) do
        create(:move, game:, player: player4, x: 3, y: 5,
                      layout:)
      end

      it 'returns a game hash' do
        expected = { game:, layouts: [], moves: [move] }
        expect(player4.opponent_game(game.id)).to eq(expected)
      end
    end

    it 'returns nil' do
      expect(player4.opponent_game(0)).to be_nil
    end
  end

  describe '#my_turn' do
    let!(:game) do
      create(:game, player1: player4, player2: player5, turn: player4)
    end

    it 'returns true' do
      expect(player4.my_turn(game.id)).to eq(1)
    end

    it 'returns false' do
      expect(player5.my_turn(game.id)).to eq(-1)
    end
  end

  describe '#cancel_game!' do
    it 'returns nil when game is not found' do
      expect(player1.cancel_game!(nil)).to be_nil
    end

    describe 'with enough time' do
      let!(:game) do
        create(:game, player1: player4, player2: player5, turn: player5)
      end

      it 'player1 gives up, player2 wins' do
        result = player4.cancel_game!(game.id)
        expect(result).to eq(game)
        expect(result.winner).to eq(player5)
        expect(result.player1.rating).to eq(1199)
        expect(result.player2.rating).to eq(1201)
      end

      it 'player2 gives up, player1 wins' do
        result = player5.cancel_game!(game.id)
        expect(result).to eq(game)
        expect(result.winner).to eq(player4)
        expect(result.player1.rating).to eq(1201)
        expect(result.player2.rating).to eq(1199)
      end
    end

    describe 'time has expired' do
      describe 'player2 has not layed out' do
        let!(:game) do
          create(:game, player1: player4, player2: player5, turn: player5,
                        player1_layed_out: true, player2_layed_out: false)
        end

        it 'player1 cancels, player1 wins' do
          travel_to(2.days.from_now) do
            result = player4.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player4)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end

        it 'player2 cancels, player1 wins' do
          travel_to(2.days.from_now) do
            result = player5.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player4)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end
      end

      describe 'player1 has not layed out' do
        let!(:game) do
          create(:game, player1: player4, player2: player5, turn: player5,
                        player1_layed_out: false, player2_layed_out: true)
        end

        it 'player2 cancels, player2 wins' do
          travel_to(2.days.from_now) do
            result = player5.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player5)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end

        it 'player1 cancels, player2 wins' do
          travel_to(2.days.from_now) do
            result = player4.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player5)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end
      end

      describe 'player1 gives up on player1 turn' do
        let!(:game) do
          create(:game, player1: player4, player2: player5, turn: player4,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player2 wins' do
          travel_to(2.days.from_now) do
            result = player4.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player5)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end
      end

      describe 'player1 gives up on player2 turn' do
        let!(:game) do
          create(:game, player1: player4, player2: player5, turn: player5,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player1 wins' do
          travel_to(2.days.from_now) do
            result = player4.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player4)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end
      end

      describe 'player2 gives up on player2 turn' do
        let!(:game) do
          create(:game, player1: player4, player2: player5, turn: player5,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player1 wins' do
          travel_to(2.days.from_now) do
            result = player5.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player4)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end
      end

      describe 'player2 gives up on player1 turn' do
        let!(:game) do
          create(:game, player1: player4, player2: player5, turn: player4,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player2 wins' do
          travel_to(2.days.from_now) do
            result = player5.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player5)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end
      end
    end
  end

  describe '#destroy_game!' do
    it 'returns nil when game is not found' do
      expect(player4.destroy_game!(nil)).to be_nil
    end

    describe 'with no winner' do
      let!(:game) do
        create(:game, player1: player4, player2: player5, turn: player5)
      end

      it 'fails to set player1 deleted' do
        expect do
          result = player4.destroy_game!(game.id)
          expect(result.del_player1).to be_falsey
        end.not_to change(Game, :count)
      end
    end

    describe 'with a winner' do
      let!(:game) do
        create(:game, player1: player4, player2: player5, turn: player5,
                      winner: player4)
      end

      it 'sets player1 deleted' do
        expect do
          result = player4.destroy_game!(game.id)
          expect(result.del_player1).to be_truthy
        end.not_to change(Game, :count)
      end

      it 'sets player2 deleted' do
        expect do
          result = player5.destroy_game!(game.id)
          expect(result.del_player2).to be_truthy
        end.not_to change(Game, :count)
      end

      it 'deletes game player2 already deleted' do
        game.update(del_player2: true)
        expect do
          player4.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end

      it 'deletes game player1 already deleted' do
        game.update(del_player1: true)
        expect do
          player5.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end
    end

    describe 'bot game' do
      let!(:game) do
        create(:game, player1: player4, player2: bot2, turn: bot2,
                      winner: player4)
      end

      it 'deletes the game' do
        expect do
          player4.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end
    end
  end

  describe '#skip_game!' do
    let!(:game) do
      create(:game, player1: player4, player2: player5, turn: player5)
    end

    it 'skips inactive opponent' do
      travel_to(2.days.from_now) do
        result = player4.skip_game!(game.id)
        expect(result).to eq(game)
        expect(result.turn).to eq(player4)
      end
    end
  end

  describe '#can_skip?' do
    let(:game) do
      build_stubbed(:game, player1:, player2:, turn: player1)
    end

    it 'returns false when game is null' do
      expect(player1).not_to be_can_skip(nil)
    end

    it 'returns false when time limit is not up' do
      expect(player1).not_to be_can_skip(game)
    end

    it 'returns false if player turn' do
      travel_to(2.days.from_now) do
        expect(player1).not_to be_can_skip(game)
      end
    end

    it 'returns false if winner' do
      game.turn = player2
      game.winner = player1
      travel_to(2.days.from_now) do
        expect(player1).not_to be_can_skip(game)
      end
    end

    it 'returns true if opponent turn' do
      game.turn = player2
      travel_to(2.days.from_now) do
        expect(player1).to be_can_skip(game)
      end
    end
  end

  describe '#next_game' do
    describe 'with no player turn games' do
      let(:game1) do
        create(:game, player1:, player2:, turn: player2,
                      player1_layed_out: true, player2_layed_out: true)
      end
      let(:game2) do
        create(:game, player1:, player2:, turn: player2,
                      player1_layed_out: true, player2_layed_out: true)
      end

      before { [game1, game2] }

      it 'returns recent opponent turn game with no time left' do
        travel_to(2.days.from_now) do
          expect(player1.next_game).to eq(game2)
        end
      end
    end

    describe 'with player turn games' do
      let(:game1) do
        create(:game, player1:, player2:, turn: player1,
                      player1_layed_out: true, player2_layed_out: true)
      end
      let(:game2) do
        create(:game, player1:, player2:, turn: player1,
                      player1_layed_out: true, player2_layed_out: true)
      end
      let(:game3) do
        create(:game, player1:, player2:, turn: player2,
                      player1_layed_out: true, player2_layed_out: true)
      end

      before { [game1, game2, game3] }

      it 'returns recent player turn game' do
        expect(player1.next_game).to eq(game2)
      end
    end

    describe 'with no games' do
      it 'returns nil' do
        expect(player1.next_game).to be_nil
      end
    end
  end

  describe '#layed_out_and_no_winner' do
    let(:game1) do
      create(:game, player1:, player2:, turn: player1,
                    player1_layed_out: true)
    end
    let(:game2) do
      create(:game, player1:, player2:, turn: player1,
                    player1_layed_out: false)
    end
    let(:game3) do
      create(:game, player1:, player2:, turn: player1,
                    player1_layed_out: true, player2_layed_out: true,
                    winner: player1)
    end
    let(:game4) do
      create(:game, player1:, player2:, turn: player1,
                    player1_layed_out: true, player2_layed_out: true)
    end

    before { [game1, game2, game3, game4] }

    it 'returns layed out games with no winner' do
      expect(player1.layed_out_and_no_winner).to eq([game4])
    end
  end

  describe '#active_games' do
    let!(:game1) do
      create(:game, player1: player4, player2: player5, turn: player4)
    end
    let!(:game2) do
      create(:game, player1: player5, player2: player4, turn: player4,
                    del_player1: true)
    end
    let(:game3) do
      create(:game, player1: player3, player2: player4, turn: player4,
                    del_player2: true)
    end

    before { game3 }

    it 'returns active games' do
      expect(player4.active_games).to eq([game1, game2])
    end
  end

  describe '#invites' do
    let!(:invite1) { create(:invite, player1:, player2:) }
    let!(:invite2) { create(:invite, player1: player2, player2: player1) }
    let(:invite3) { create(:invite, player1: player2, player2: player3) }

    before { invite3 }

    it 'returns invites' do
      expect(player1.invites).to eq([invite1, invite2])
    end
  end

  describe '.list_for_game' do
    let(:game) do
      create(:game, player1: player4, player2: bot2, turn: player4)
    end

    it 'returns game players' do
      expected = [player4, bot2]
      expect(described_class.list_for_game(game.id)).to eq(expected)
    end
  end

  describe '.list' do
    let(:player11) { create(:player, :confirmed) }
    let(:player12) { create(:player, :confirmed) }
    let(:player13) { create(:player, :confirmed) }
    let(:enemy) { create(:enemy, player1:, player2:) }

    before { enemy }

    it 'returns players' do
      expected = [player5, player11, player13]
      expect(described_class.list(player1)).to eq(expected)
    end

    describe 'non-confirmed' do
      let(:player13) { create(:player) }

      before { player13 }

      it 'returns players' do
        expected = [player5, player11]
        expect(described_class.list(player1)).to eq(expected)
      end
    end
  end

  describe '.generate_password' do
    let(:password) { described_class.generate_password(16) }

    it 'returns a generated password' do
      expect(password.length).to eq(16)
    end
  end

  describe '#last' do
    let(:player1) { build(:player, updated_at: Time.current) }
    let(:player2) { build(:player, updated_at: 2.hours.ago) }
    let(:player3) { build(:player, updated_at: 2.days.ago) }
    let(:player4) { build(:player, updated_at: 4.days.ago) }
    let(:player5) { build(:player, updated_at: nil) }
    let(:bot) { build(:player, :bot) }

    it 'signed in recently returns a 0' do
      expect(player1.last).to eq(0)
    end

    it 'signed in 2 hours ago returns a 1' do
      expect(player2.last).to eq(1)
    end

    it 'signed in 2 days ago returns a 2' do
      expect(player3.last).to eq(2)
    end

    it 'signed in 4 days ago returns a 3' do
      expect(player4.last).to eq(3)
    end

    it 'never logged in returns a 3' do
      expect(player5.last).to eq(3)
    end

    it 'bot returns a 0' do
      expect(bot.last).to eq(0)
    end
  end
end
