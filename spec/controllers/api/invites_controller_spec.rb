# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::InvitesController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #create' do
    it 'returns http success' do
      get :create
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #accept' do
    it 'returns http success' do
      get :accept
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #decline' do
    it 'returns http success' do
      get :decline
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #cancel' do
    it 'returns http success' do
      get :cancel
      expect(response).to have_http_status(:success)
    end
  end
end
