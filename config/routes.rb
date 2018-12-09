# frozen_string_literal: true

Rails.application.routes.draw do # rubocop:disable Metrics/BlockLength
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

    resources :players, only: %i[index create] do
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
    resources :sessions, only: %i[create] do
      collection do
        delete :destroy
      end
    end
  end

  get '/android', to: 'home#android'
  get '/confirm/:token', to: 'home#confirm', as: :confirm

  ActiveAdmin.routes(self)
  namespace :admin do
    resources :sessions, only: %i[new create destroy]
  end

  root to: 'home#index'
end
