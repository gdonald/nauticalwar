# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PlayersController do # rubocop:disable /BlockLength, Metrics/
  let(:player) { create(:player, :confirmed) }

  describe 'GET #index' do
    let(:json) { response.parsed_body }
    let(:player_two) { create(:player, :confirmed) }
    let(:game) do
      create(:game, player1: player, player2: player_two, turn: player)
    end

    it 'returns player players' do
      get :index, params: { format: :json }, session: { player_id: player.id }
      expect(response).to be_successful
      expect(json[0]['id']).to eq(player.id)
      expect(json[0]['name']).to eq(player.name)
      expect(json[0]['wins']).to eq(0)
      expect(json[0]['losses']).to eq(0)
      expect(json[0]['rating']).to eq(1200)
      expect(json[0]['last']).to eq(0)
      expect(json[0]['bot']).to eq(0)
    end

    it 'returns game players' do
      get :index, params: { format: :json, game_id: game.id },
                  session: { player_id: player.id }
      expect(response).to be_successful
      expect(json.size).to eq(2)
      expect(json[0]['id']).to eq(player.id)
      expect(json[0]['name']).to eq(player.name)
      expect(json[0]['wins']).to eq(0)
      expect(json[0]['losses']).to eq(0)
      expect(json[0]['rating']).to eq(1200)
      expect(json[0]['last']).to eq(0)
      expect(json[0]['bot']).to eq(0)
      expect(json[1]['id']).to eq(player_two.id)
      expect(json[1]['name']).to eq(player_two.name)
      expect(json[1]['wins']).to eq(0)
      expect(json[1]['losses']).to eq(0)
      expect(json[1]['rating']).to eq(1200)
      expect(json[1]['last']).to eq(0)
      expect(json[1]['bot']).to eq(0)
    end
  end

  describe 'GET #show' do
    let(:json) { response.parsed_body }
    let(:player_two) { create(:player, :confirmed) }

    it 'returns a player' do
      get :show, params: { format: :json, id: player_two.id }, session: { player_id: player.id }
      expect(response).to be_successful
      expect(json['id']).to eq(player_two.id)
      expect(json['name']).to eq(player_two.name)
      expect(json['wins']).to eq(0)
      expect(json['losses']).to eq(0)
      expect(json['rating']).to eq(1200)
      expect(json['last']).to eq(0)
      expect(json['bot']).to eq(0)
    end
  end

  describe 'POST #reset_password' do
    let(:json) { response.parsed_body }

    describe 'cannot find a player' do
      it 'with an invalid token' do
        post :reset_password, params: { token: 'foo' }
        expect(response).to be_successful
        expect(json['id']).to eq(-1)
      end
    end

    describe 'finds a player' do
      let(:params) do
        { token: player.password_token, password: 'foo',
          password_confirmation: 'foo' }
      end

      before do
        player.reset_password_token
      end

      it 'with an expired token' do
        travel_to 2.hours.from_now do
          post(:reset_password, params:)
          expect(response).to be_successful
          expect(json['id']).to eq(-2)
        end
      end

      it 'cannot update with different passwords' do
        params[:password] = 'bar'
        post(:reset_password, params:)
        expect(response).to be_successful
        expect(json['id']).to eq(-3)
      end

      it 'updates a player password' do
        post(:reset_password, params:)
        expect(response).to be_successful
        expect(json['id']).to eq(player.id)
      end
    end
  end

  describe 'POST #locate_account' do
    let(:json) { response.parsed_body }
    let(:params) { { email: player.email } }

    it 'finds a player' do
      post(:locate_account, params:)
      expect(response).to be_successful
      expect(json['id']).to eq(player.id)
    end

    it 'fails to find a player' do
      post :locate_account, params: { email: 'foo@bar.com' }
      expect(response).to be_successful
      expect(json['id']).to eq(-1)
    end
  end

  describe 'GET #activity' do
    let(:json) { response.parsed_body }

    it 'returns http success' do
      get :activity, params: { format: :json },
                     session: { player_id: player.id }
      expect(response).to be_successful
      expect(json['activity']).to eq(0)
    end
  end

  describe 'POST #create' do
    let(:params) do
      { email: 'foo@bar.com',
        name: 'foo',
        password: 'changeme',
        password_confirmation: 'changeme' }
    end
    let(:json) { response.parsed_body }
    let(:player) { Player.last }

    it 'creates a player' do
      expect do
        post(:create, params:)
      end.to change(Player, :count).by(1)
      expect(json['id']).to eq(player.id)
    end

    it 'returns errors' do
      expect do
        post :create, params: {}
      end.not_to change(Player, :count)
      expect(json['errors']['email']).to eq(["can't be blank", 'is not valid'])
      expect(json['errors']['name']).to eq(["can't be blank"])
      expect(json['errors']['password']).to eq(["can't be blank"])
      expect(json['errors']['password_confirmation']).to eq(["can't be blank"])
    end
  end

  describe 'POST #account_exists' do
    let(:player) { create(:player) }
    let(:params) { { email: player.email } }
    let(:json) { response.parsed_body }

    it 'returns a player' do
      post(:account_exists, params:)
      expect(json['id']).to eq(player.id)
    end

    it 'does not return a player' do
      post :account_exists, params: {}
      expect(json).to be_nil
    end
  end

  describe 'POST #complete_google_signup' do
    let(:params) { { email: 'foo@bar.com', name: 'foo' } }
    let(:json) { response.parsed_body }
    let(:player) { Player.last }

    it 'creates a player' do
      expect do
        post(:complete_google_signup, params:)
      end.to change(Player, :count).by(1)
      expect(json['id']).to eq(player.id)
    end

    describe 'with an existing player' do
      let(:player) { create(:player) }
      let!(:params) { { email: player.email, name: player.name } }

      it 'returns errors' do
        expect do
          post(:complete_google_signup, params:)
        end.not_to change(Player, :count)
        expect(json['errors']['email']).to eq(['has already been taken'])
        expect(json['errors']['name']).to eq(['has already been taken'])
      end
    end
  end
end
