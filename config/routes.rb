# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
  ActiveAdmin.routes(self)

  namespace :api do # rubocop:disable Metrics/BlockLength
    resources :ping, only: [:index]

    resources :games, only: %i[index show destroy] do
      member do
        get :opponent
        get :my_turn
        post :cancel
        post :attack
        post :skip
      end
      collection do
        get :count
        get :next
      end
    end

    resources :layouts, only: %i[create show]

    resources :players, only: [:index] do
      collection do
        get :activity
      end
    end

    resources :invites, only: %i[index create] do
      member do
        post :accept
        delete :decline
        delete :cancel
      end
      collection do
        get :count
      end
    end

    resources :friends, only: %i[index create destroy]
    resources :enemies, only: %i[create]
  end

  get '/android', to: 'home#android'

  root to: 'home#index'
end
