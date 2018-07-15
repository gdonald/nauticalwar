Rails.application.routes.draw do

  namespace :api do
    resources :ping, only: [:index]
    devise_for :users, controllers: { sessions: 'api/sessions' }
  end

  root to: 'home#index'
end
