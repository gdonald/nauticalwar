# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #android' do
    it 'returns http success' do
      get :android
      expect(response).to be_successful
      expect(response).to render_template(layout: nil)
    end
  end
end
