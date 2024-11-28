Rails.application.routes.draw do
  # Public routes
  root "home#index"

  # Authentication routes (currently mocked)
  # TODO: Replace with real authentication routes
  get "/sign_in", to: "sessions#new", as: :sign_in
  get "/sign_out", to: "sessions#destroy", as: :sign_out

  # Main feature routes
  get "/summary", to: "summaries#show" # For showing individual summaries

  # Channel features
  resources :channels, only: [ :show ] do
    resources :videos, only: [ :index ], controller: "channels/videos"
  end
end
