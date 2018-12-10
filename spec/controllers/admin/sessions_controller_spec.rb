# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :controller do # rubocop:disable Metrics/BlockLength, Metrics/LineLength
  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:admin) { create(:player, :admin) }
    let(:params) do
      { email: admin.email, password: 'changeme' }
    end

    it 'returns a redirect' do
      post :create, params: params
      expect(response).to be_redirect
    end

    it 'render :new' do
      post :create, params: {}
      expect(response).to render_template(:new)
    end
  end

  describe 'GET #logout' do
    it 'returns a redirect' do
      get :logout
      expect(response).to be_redirect
    end
  end
end
