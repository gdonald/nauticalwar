# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player do
  let_it_be(:player_four) { create(:player, name: 'player_four') }
  let_it_be(:player_five) { create(:player, :confirmed, name: 'player_five') }

  let(:player_one) { build_stubbed(:player, id: 1, name: 'player1') }
  let(:player_two) { build_stubbed(:player, :confirmed, id: 2) }
  let(:player_three) { build_stubbed(:player, id: 3) }
  let(:bot_one) { build_stubbed(:player, :bot, id: 4) }
  let(:bot_two) { create(:player, :bot) }
  let(:bot_three) { create(:player, :bot) }

  describe '#to_s' do
    it 'returns a string' do
      expect(player_one.to_s).to eq(player_one.name)
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
        { token: player_four.password_token, password: 'foo',
          password_confirmation: 'foo' }
      end

      before do
        player_four.reset_password_token
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
        expect(result).to eq(id: player_four.id)
      end
    end
  end

  describe '.locate_account' do
    let(:params) { { email: player_four.email } }

    it 'finds a player' do
      result = described_class.locate_account(params)
      expect(result).to eq(id: player_four.id)
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
      let(:params) { { email: player_four.email, password: 'wrong' } }

      it 'does not authenticate a confirmed player' do
        player_four.update(confirmed_at: Time.zone.now)
        expect(result).to eq(error: 'Login failed')
      end

      it 'does not authenticate an unconfirmed player' do
        expect(result).to eq(error: 'Email not confirmed')
      end
    end

    describe 'valid params' do
      let(:params) { { email: player_four.email, password: 'changeme' } }

      before do
        player_four.update(last_sign_in_at: nil)
      end

      it 'authenticates a confirmed player' do
        player_four.update(confirmed_at: Time.zone.now)
        expect(player_four.last_sign_in_at).not_to be_present
        expect(result).to eq(id: player_four.id)
        player_four.reload
        expect(player_four.last_sign_in_at).to be_present
      end

      it 'fails to authenticate an unconfirmed player' do
        expect(player_four.last_sign_in_at).not_to be_present
        expect(result).to eq(error: 'Email not confirmed')
        player_four.reload
        expect(player_four.last_sign_in_at).not_to be_present
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
      described_class.confirm_email(player_four.confirmation_token)
      player_four.reload
      expect(player_four.confirmed_at).to be_present
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
    let(:invite) { create(:invite, player1: player_one, player2: player_two) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player_one.cancel_invite!(id)
      end.not_to change(Game, :count)
      expect(Invite.find_by(id:)).to be_nil
    end
  end

  describe '#decline_invite!' do
    let(:invite) { create(:invite, player1: player_one, player2: player_two) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player_two.decline_invite!(id)
      end.not_to change(Game, :count)
      expect(Invite.find_by(id:)).to be_nil
    end
  end

  describe '#accept_invite!' do
    let(:invite) { create(:invite, player1: player_four, player2: player_five) }
    let(:id) { invite.id }

    it 'accepts an invite' do
      expect do
        player_five.accept_invite!(id)
      end.to change(Game, :count).by(1)
      expect(Invite.find_by(id:)).to be_nil
    end
  end

  describe '#create_invite!' do
    let(:params) { { id: 0, r: '1', s: '1', t: '300' } }

    it 'fails to create an invite' do
      expect do
        player_one.create_invite!(params)
      end.not_to change(Invite, :count)
    end

    it 'creates an invite' do
      player_five.save!
      params[:id] = player_five.id
      expect do
        player_four.create_invite!(params)
      end.to change(Invite, :count).by(1)
    end

    it 'creates a game' do
      params[:id] = bot_two.id
      expect do
        player_four.create_invite!(params)
      end.to change(Game, :count).by(1)
    end
  end

  describe '#create_bot_game!' do
    let(:args) do
      { player2: bot_two,
        rated: true,
        shots_per_turn: 5,
        time_limit: 86_400 }
    end

    it 'creates a bot game' do
      expect do
        game = player_four.create_bot_game!(args)
        expect(game.player1).to eq(player_four)
        expect(game.player2).to eq(bot_two)
        expect(game.rated).to be_truthy
        expect(game.shots_per_turn).to eq(5)
        expect(game.time_limit).to eq(86_400)
      end.to change(Game, :count).by(1)
    end
  end

  describe '#create_opponent_invite!' do
    let(:args) do
      { player2: player_five,
        rated: true,
        shots_per_turn: 5,
        time_limit: 86_400 }
    end

    it 'creates an opponent invite' do
      expect do
        invite = player_four.create_opponent_invite!(args)
        expect(invite.player1).to eq(player_four)
        expect(invite.player2).to eq(player_five)
        expect(invite.rated).to be_truthy
        expect(invite.shots_per_turn).to eq(5)
        expect(invite.time_limit).to eq(86_400)
      end.to change(Invite, :count).by(1)
    end
  end

  describe '#invite_args' do
    let(:params) { { id: player_five.id, r: '1', s: '5', t: '86400' } }

    it 'returns a hash of invite args' do
      args = player_four.invite_args(params)
      expect(args[:player2]).to eq(player_five)
      expect(args[:rated]).to be_truthy
      expect(args[:shots_per_turn]).to eq(5)
      expect(args[:time_limit]).to eq(86_400)
    end
  end

  describe '#create_enemy!' do
    it 'creates a enemy' do
      expect do
        player_four.create_enemy!(player_five.id)
      end.to change(Enemy, :count).by(1)
      expect(player_four.enemies.first.player2).to eq(player_five)
    end

    describe 'fails to create a enemy' do
      it 'when player not found' do
        expect do
          result = player_four.create_enemy!(0)
          expect(result).to eq(-1)
        end.not_to change(Enemy, :count)
      end

      describe 'fails to add enemy' do
        let(:friend) { create(:friend, player1: player_four, player2: player_five) }

        before { friend }

        it 'when already a friend' do
          expect do
            result = player_four.create_enemy!(player_five.id)
            expect(result).to eq(-1)
          end.not_to change(Enemy, :count)
        end
      end
    end
  end

  describe '#enemy_ids' do
    let(:enemy_one) { create(:enemy, player1: player_one, player2: player_two) }
    let(:enemy_two) { create(:enemy, player1: player_two, player2: player_three) }
    let(:enemy_three) { create(:enemy, player1: player_two, player2: player_one) }

    before { [enemy_one, enemy_two, enemy_three] }

    it 'returns enemy ids' do
      expect(Enemy.count).to eq(3)
      expect(player_one.enemies_player_ids).to eq([player_two.id])
    end
  end

  describe '#destroy_friend!' do
    let(:friend) { create(:friend, player1: player_one, player2: player_two) }

    before { friend }

    it 'destroys a friend' do
      expect do
        player_one.destroy_friend!(player_two.id)
      end.to change(Friend, :count).by(-1)
      expect(player_one.friends).to eq([])
    end

    it 'fails to destroy a friend' do
      expect do
        result = player_one.destroy_friend!(0)
        expect(result).to eq(-1)
      end.not_to change(Friend, :count)
    end
  end

  describe '#create_friend!' do
    it 'creates a friend' do
      player_five.save!
      expect do
        player_four.reload.create_friend!(player_five.id)
      end.to change(Friend, :count).by(1)
      expect(player_four.friends.first.player2).to eq(player_five)
    end

    describe 'fails to create a friend' do
      it 'when other player not found' do
        expect do
          result = player_four.create_friend!(0)
          expect(result).to eq(-1)
        end.not_to change(Friend, :count)
      end

      describe 'fails to add a friend' do
        let(:enemy) { create(:enemy, player1: player_four, player2: player_five) }

        before { enemy }

        it 'when already an enemy' do
          expect do
            result = player_four.create_friend!(player_five.id)
            expect(result).to eq(-1)
          end.not_to change(Friend, :count)
        end
      end
    end
  end

  describe '#friend_ids' do
    let(:friend_one) { create(:friend, player1: player_one, player2: player_two) }
    let(:friend_two) { create(:friend, player1: player_two, player2: player_three) }
    let(:friend_three) { create(:friend, player1: player_two, player2: player_one) }

    before { [friend_one, friend_two, friend_three] }

    it 'returns friend ids' do
      expect(Friend.count).to eq(3)
      expect(player_one.friends_player_ids).to eq([player_two.id])
    end
  end

  describe '#attack!' do
    let(:game) do
      create(:game, shots_per_turn: 5, player1: player_four, player2: bot_two, turn: player_four)
    end
    let(:ship) { create(:ship, size: 3) }
    let(:layout_one) do
      create(:layout, game:, player: player_four, ship:, x: 0, y: 0)
    end
    let(:layout_two) do
      create(:layout, game:, player: player_four, ship:, x: 1, y: 1)
    end
    let(:layout_three) do
      create(:layout, game:, player: player_four, ship:, x: 2, y: 2)
    end
    let(:layout_four) do
      create(:layout, game:, player: player_four, ship:, x: 3, y: 3)
    end
    let(:layout_five) do
      create(:layout, game:, player: player_four, ship:, x: 4, y: 4)
    end
    let(:layout) do
      create(:layout, game:, player: bot_two, ship:, x: 0, y: 0)
    end
    let(:json) do
      [{ x: 5, y: 5 },
       { x: 4, y: 6 },
       { x: 6, y: 6 },
       { x: 3, y: 7 },
       { x: 2, y: 8 }].to_json
    end
    let(:params) { { s: json } }

    before { [layout, layout_one, layout_two, layout_three, layout_four, layout_five] }

    it 'saves an attack' do
      expect do
        player_four.attack!(game, params)
      end.to change(Move, :count).by(10)
      expect(game.winner).to be_nil
      expect(game.turn).to eq(player_four)
    end
  end

  describe '#record_shots!' do
    let(:game) do
      create(:game, shots_per_turn: 5, player1: player_four, player2: player_five, turn: player_four)
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
        player_four.record_shots!(game, json)
      end.to change(Move, :count).by(5)
      expect(game.turn).to eq(player_five)
    end
  end

  describe '#record_shot!' do
    let(:game) do
      create(:game, player1: player_four, player2: player_five, turn: player_four)
    end
    let!(:layout) do
      create(:layout, game:, player: player_five, ship: create(:ship),
                      x: 3, y: 5)
    end

    describe 'when shot already exists' do
      let(:move) do
        create(:move, game:, player: player_four, x: 3, y: 5,
                      layout:)
      end

      before { move }

      it 'does not record a shot' do
        expect do
          player_four.record_shot!(game, 3, 5)
        end.not_to change(Move, :count)
      end
    end

    describe 'when shot does not already exists' do
      it 'records a hit' do
        expect do
          player_four.record_shot!(game, 3, 5)
        end.to change(Move, :count).by(1)
        expect(Move.last.layout).to eq(layout)
      end

      it 'records a miss' do
        expect do
          player_four.record_shot!(game, 5, 6)
        end.to change(Move, :count).by(1)
        expect(Move.last.layout).to be_nil
      end
    end
  end

  describe '#new_activity' do
    it 'increments player activity' do
      expect do
        player_four.new_activity!
      end.to change(player_four, :activity).by(1)
    end
  end

  describe '#player_game' do
    describe 'game exists' do
      let(:game) do
        create(:game, player1: player_four, player2: player_five, turn: player_five)
      end
      let(:layout) do
        create(:layout, game:, player: player_four, ship: create(:ship),
                        x: 3, y: 5)
      end
      let!(:move) do
        create(:move, game:, player: player_five, x: 3, y: 5,
                      layout:)
      end

      it 'returns a game hash' do
        expected = { game:, layouts: [layout], moves: [move] }
        expect(player_four.player_game(game.id)).to eq(expected)
      end
    end

    it 'returns nil' do
      expect(player_four.player_game(0)).to be_nil
    end
  end

  describe '#opponent_game' do
    describe 'game exists' do
      let(:game) do
        create(:game, player1: player_four, player2: player_five, turn: player_five)
      end
      let(:layout) do
        create(:layout, game:, player: player_five, ship: create(:ship),
                        x: 3, y: 5)
      end
      let!(:move) do
        create(:move, game:, player: player_four, x: 3, y: 5,
                      layout:)
      end

      it 'returns a game hash' do
        expected = { game:, layouts: [], moves: [move] }
        expect(player_four.opponent_game(game.id)).to eq(expected)
      end
    end

    it 'returns nil' do
      expect(player_four.opponent_game(0)).to be_nil
    end
  end

  describe '#my_turn' do
    let!(:game) do
      create(:game, player1: player_four, player2: player_five, turn: player_four)
    end

    it 'returns true' do
      expect(player_four.my_turn(game.id)).to eq(1)
    end

    it 'returns false' do
      expect(player_five.my_turn(game.id)).to eq(-1)
    end
  end

  describe '#cancel_game!' do
    it 'returns nil when game is not found' do
      expect(player_one.cancel_game!(nil)).to be_nil
    end

    describe 'with enough time' do
      let!(:game) do
        create(:game, player1: player_four, player2: player_five, turn: player_five)
      end

      it 'player1 gives up, player2 wins' do
        result = player_four.cancel_game!(game.id)
        expect(result).to eq(game)
        expect(result.winner).to eq(player_five)
        expect(result.player1.rating).to eq(1199)
        expect(result.player2.rating).to eq(1201)
      end

      it 'player2 gives up, player1 wins' do
        result = player_five.cancel_game!(game.id)
        expect(result).to eq(game)
        expect(result.winner).to eq(player_four)
        expect(result.player1.rating).to eq(1201)
        expect(result.player2.rating).to eq(1199)
      end
    end

    describe 'time has expired' do
      describe 'player2 has not layed out' do
        let!(:game) do
          create(:game, player1: player_four, player2: player_five, turn: player_five,
                        player1_layed_out: true, player2_layed_out: false)
        end

        it 'player1 cancels, player1 wins' do
          travel_to(2.days.from_now) do
            result = player_four.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_four)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end

        it 'player2 cancels, player1 wins' do
          travel_to(2.days.from_now) do
            result = player_five.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_four)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end
      end

      describe 'player1 has not layed out' do
        let!(:game) do
          create(:game, player1: player_four, player2: player_five, turn: player_five,
                        player1_layed_out: false, player2_layed_out: true)
        end

        it 'player2 cancels, player2 wins' do
          travel_to(2.days.from_now) do
            result = player_five.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_five)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end

        it 'player1 cancels, player2 wins' do
          travel_to(2.days.from_now) do
            result = player_four.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_five)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end
      end

      describe 'player1 gives up on player1 turn' do
        let!(:game) do
          create(:game, player1: player_four, player2: player_five, turn: player_four,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player2 wins' do
          travel_to(2.days.from_now) do
            result = player_four.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_five)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end
      end

      describe 'player1 gives up on player2 turn' do
        let!(:game) do
          create(:game, player1: player_four, player2: player_five, turn: player_five,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player1 wins' do
          travel_to(2.days.from_now) do
            result = player_four.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_four)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end
      end

      describe 'player2 gives up on player2 turn' do
        let!(:game) do
          create(:game, player1: player_four, player2: player_five, turn: player_five,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player1 wins' do
          travel_to(2.days.from_now) do
            result = player_five.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_four)
            expect(result.player1.rating).to eq(1201)
            expect(result.player2.rating).to eq(1199)
          end
        end
      end

      describe 'player_two gives up on player1 turn' do
        let!(:game) do
          create(:game, player1: player_four, player2: player_five, turn: player_four,
                        player1_layed_out: true, player2_layed_out: true)
        end

        it 'player_two wins' do
          travel_to(2.days.from_now) do
            result = player_five.cancel_game!(game.id)
            expect(result).to eq(game)
            expect(result.winner).to eq(player_five)
            expect(result.player1.rating).to eq(1199)
            expect(result.player2.rating).to eq(1201)
          end
        end
      end
    end
  end

  describe '#destroy_game!' do
    it 'returns nil when game is not found' do
      expect(player_four.destroy_game!(nil)).to be_nil
    end

    describe 'with no winner' do
      let!(:game) do
        create(:game, player1: player_four, player2: player_five, turn: player_five)
      end

      it 'fails to set player1 deleted' do
        expect do
          result = player_four.destroy_game!(game.id)
          expect(result.del_player1).to be_falsey
        end.not_to change(Game, :count)
      end
    end

    describe 'with a winner' do
      let!(:game) do
        create(:game, player1: player_four, player2: player_five, turn: player_five,
                      winner: player_four)
      end

      it 'sets player1 deleted' do
        expect do
          result = player_four.destroy_game!(game.id)
          expect(result.del_player1).to be_truthy
        end.not_to change(Game, :count)
      end

      it 'sets player2 deleted' do
        expect do
          result = player_five.destroy_game!(game.id)
          expect(result.del_player2).to be_truthy
        end.not_to change(Game, :count)
      end

      it 'deletes game player2 already deleted' do
        game.update(del_player2: true)
        expect do
          player_four.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end

      it 'deletes game player1 already deleted' do
        game.update(del_player1: true)
        expect do
          player_five.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end
    end

    describe 'bot game' do
      let!(:game) do
        create(:game, player1: player_four, player2: bot_two, turn: bot_two,
                      winner: player_four)
      end

      it 'deletes the game' do
        expect do
          player_four.destroy_game!(game.id)
        end.to change(Game, :count).by(-1)
      end
    end
  end

  describe '#skip_game!' do
    let!(:game) do
      create(:game, player1: player_four, player2: player_five, turn: player_five)
    end

    it 'skips inactive opponent' do
      travel_to(2.days.from_now) do
        result = player_four.skip_game!(game.id)
        expect(result).to eq(game)
        expect(result.turn).to eq(player_four)
      end
    end
  end

  describe '#can_skip?' do
    let(:game) do
      build_stubbed(:game, player1: player_one, player2: player_two, turn: player_one)
    end

    it 'returns false when game is null' do
      expect(player_one).not_to be_can_skip(nil)
    end

    it 'returns false when time limit is not up' do
      expect(player_one).not_to be_can_skip(game)
    end

    it 'returns false if player turn' do
      travel_to(2.days.from_now) do
        expect(player_one).not_to be_can_skip(game)
      end
    end

    it 'returns false if winner' do
      game.turn = player_two
      game.winner = player_one
      travel_to(2.days.from_now) do
        expect(player_one).not_to be_can_skip(game)
      end
    end

    it 'returns true if opponent turn' do
      game.turn = player_two
      travel_to(2.days.from_now) do
        expect(player_one).to be_can_skip(game)
      end
    end
  end

  describe '#next_game' do
    describe 'with no player turn games' do
      let(:game_one) do
        create(:game, player1: player_one, player2: player_two, turn: player_two,
                      player1_layed_out: true, player2_layed_out: true)
      end
      let(:game_two) do
        create(:game, player1: player_one, player2: player_two, turn: player_two,
                      player1_layed_out: true, player2_layed_out: true)
      end

      before { [game_one, game_two] }

      it 'returns recent opponent turn game with no time left' do
        travel_to(2.days.from_now) do
          expect(player_one.next_game).to eq(game_two)
        end
      end
    end

    describe 'with player turn games' do
      let(:game_one) do
        create(:game, player1: player_one, player2: player_two, turn: player_one,
                      player1_layed_out: true, player2_layed_out: true)
      end
      let(:game_two) do
        create(:game, player1: player_one, player2: player_two, turn: player_one,
                      player1_layed_out: true, player2_layed_out: true)
      end
      let(:game_three) do
        create(:game, player1: player_one, player2: player_two, turn: player_two,
                      player1_layed_out: true, player2_layed_out: true)
      end

      before { [game_one, game_two, game_three] }

      it 'returns recent player turn game' do
        expect(player_one.next_game).to eq(game_two)
      end
    end

    describe 'with no games' do
      it 'returns nil' do
        expect(player_one.next_game).to be_nil
      end
    end
  end

  describe '#layed_out_and_no_winner' do
    let(:game_one) do
      create(:game, player1: player_one, player2: player_two, turn: player_one,
                    player1_layed_out: true)
    end
    let(:game_two) do
      create(:game, player1: player_one, player2: player_two, turn: player_one,
                    player1_layed_out: false)
    end
    let(:game_three) do
      create(:game, player1: player_one, player2: player_two, turn: player_one,
                    player1_layed_out: true, player2_layed_out: true,
                    winner: player_one)
    end
    let(:game_four) do
      create(:game, player1: player_one, player2: player_two, turn: player_one,
                    player1_layed_out: true, player2_layed_out: true)
    end

    before { [game_one, game_two, game_three, game_four] }

    it 'returns layed out games with no winner' do
      expect(player_one.layed_out_and_no_winner).to eq([game_four])
    end
  end

  describe '#active_games' do
    let!(:game_one) do
      create(:game, player1: player_four, player2: player_five, turn: player_four)
    end
    let!(:game_two) do
      create(:game, player1: player_five, player2: player_four, turn: player_four,
                    del_player1: true)
    end
    let(:game_three) do
      create(:game, player1: player_three, player2: player_four, turn: player_four,
                    del_player2: true)
    end

    before { game_three }

    it 'returns active games' do
      expect(player_four.active_games).to eq([game_one, game_two])
    end
  end

  describe '#invites' do
    let(:invite_one) { create(:invite, player1: player_one, player2: player_two) }
    let(:invite_two) { create(:invite, player1: player_two, player2: player_one) }
    let(:invite_three) { create(:invite, player1: player_two, player2: player_three) }

    before do
      [invite_one, invite_two, invite_three]
    end

    it 'returns invites' do
      expect(player_one.invites).to eq([invite_one, invite_two])
    end
  end

  describe '.list_for_game' do
    let(:game) do
      create(:game, player1: player_four, player2: bot_two, turn: player_four)
    end

    it 'returns game players' do
      expected = [player_four, bot_two]
      expect(described_class.list_for_game(game.id)).to match_array(expected)
    end
  end

  describe '.list' do
    let(:player_eleven) { create(:player, :confirmed) }
    let(:player_twelve) { create(:player, :confirmed) }
    let(:player_thirteen) { create(:player, :confirmed) }
    let(:enemy) { create(:enemy, player1: player_one, player2: player_two) }

    before { enemy }

    it 'returns players' do
      expected = [player_five, player_eleven, player_thirteen]
      expect(described_class.list(player_one)).to match_array(expected)
    end

    describe 'non-confirmed' do
      let(:player_thirteen) { create(:player) }

      before { player_thirteen }

      it 'returns players' do
        expected = [player_five, player_eleven]
        expect(described_class.list(player_one)).to match_array(expected)
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
    let(:player_one) { build(:player, updated_at: Time.current) }
    let(:player_two) { build(:player, updated_at: 2.hours.ago) }
    let(:player_three) { build(:player, updated_at: 2.days.ago) }
    let(:player_four) { build(:player, updated_at: 4.days.ago) }
    let(:player_five) { build(:player, updated_at: nil) }
    let(:bot) { build(:player, :bot) }

    it 'signed in recently returns a 0' do
      expect(player_one.last).to eq(0)
    end

    it 'signed in 2 hours ago returns a 1' do
      expect(player_two.last).to eq(1)
    end

    it 'signed in 2 days ago returns a 2' do
      expect(player_three.last).to eq(2)
    end

    it 'signed in 4 days ago returns a 3' do
      expect(player_four.last).to eq(3)
    end

    it 'never logged in returns a 3' do
      expect(player_five.last).to eq(3)
    end

    it 'bot returns a 0' do
      expect(bot.last).to eq(0)
    end
  end
end
