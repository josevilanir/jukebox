Rails.application.routes.draw do
  get "home/index"

  resources :rooms, param: :slug, only: %i[index new create show] do
    member do
      get  :history
      post :play_next
      patch :toggle_dj_mode
      patch :close
      patch :seek
    end

    resource :search, only: [ :show ], controller: "room_searches"

    resources :queue_items, only: %i[create destroy] do
      resources :votes, only: %i[create destroy]
      resources :skip_votes, only: [ :create ]
    end

    resources :messages, only: %i[create]
    resources :room_memberships, only: %i[create]
  end

  root "rooms#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
