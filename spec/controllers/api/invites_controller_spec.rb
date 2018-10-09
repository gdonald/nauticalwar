# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::InvitesController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET #create' do
    it 'returns http success' do
      get :create
      expect(response).to have_http_status(:redirect)
    end
  end
end
