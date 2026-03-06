Rails.application.routes.draw do
  get "home/index"

  resource :user, only: [:update]

  resources :rooms, param: :slug, only: %i[index new create show] do
    member do
      post :play_next
      patch :toggle_dj_mode
      patch :close
      patch :seek
    end

    resources :queue_items, only: %i[create destroy] do
      resources :votes, only: %i[create destroy]
      resources :skip_votes, only: [:create]
    end

    resources :messages, only: %i[create]
  end

  root "rooms#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
