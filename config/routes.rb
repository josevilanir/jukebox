Rails.application.routes.draw do
  # Rotas principais para Rooms
  resources :rooms, param: :slug, only: %i[index new create show]

  # Rota inicial
  root "rooms#index"

  # Health check (opcional, útil para deploys)
  get "up" => "rails/health#show", as: :rails_health_check
end
