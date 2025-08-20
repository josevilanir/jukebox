Rails.application.routes.draw do
  resources :rooms, param: :slug, only: %i[index new create show] do
    post :play_next, on: :member

    resources :queue_items, only: %i[create destroy] do
      resources :votes, only: %i[create destroy]
    end

    resources :messages, only: %i[create]
  end

  root "rooms#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
