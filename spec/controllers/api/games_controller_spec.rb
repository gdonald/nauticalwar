require 'rails_helper'

RSpec.describe Api::GamesController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #count" do
    it "returns http success" do
      get :count
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #next" do
    it "returns http success" do
      get :next
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #destroy" do
    it "returns http success" do
      get :destroy
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #cancel" do
    it "returns http success" do
      get :cancel
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #opponent" do
    it "returns http success" do
      get :opponent
      expect(response).to have_http_status(:success)
    end
  end

end
