Rails.application.routes.draw do

  namespace :api do

    resources :ping, only: [:index]

    resources :games, only: %i[index show destroy] do
      member do
        get :opponent
        post :cancel
        post :attack
      end
      collection do
        get :count
        get :next
      end
    end

    resources :layouts, only: %i[create show]

    resources :users, only: [:index] do
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

    devise_for :users, controllers: { sessions: 'api/sessions' }
  end

  root to: 'home#index'
end
