# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardController do
  describe 'GET #index' do
    it 'returns a redirect' do
      get :index
      expect(response).to be_redirect
    end
  end
end
