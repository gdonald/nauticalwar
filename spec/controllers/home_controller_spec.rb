# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #confirm' do
    let(:player) { create(:player) }

    it 'returns redirect' do
      get :confirm, params: { token: player.confirmation_token }
      expect(response).to be_redirect
    end
  end

  describe 'GET #reset' do
    let(:player) { create(:player) }

    it 'returns redirect' do
      get :reset, params: { token: player.confirmation_token }
      expect(response).to be_redirect
    end
  end

  describe 'GET #reset_complete' do
    let(:player) { create(:player) }

    it 'returns redirect' do
      get :reset_complete, params: { reset_complete: 1 }
      expect(response).to be_redirect
    end
  end
end
