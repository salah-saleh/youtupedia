Rails.application.routes.draw do
  root "home#index"

  resources :summaries, only: [ :show, :index ] do
    collection do
      get :create_from_url
    end
    member do
      get :check_status
      post :ask_gpt
    end
  end

  resources :channels, only: [ :index, :show, :create ]
  post "/parse_youtube_url", to: "youtube_urls#parse"

  # Authentication routes
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [ :new, :create ]

  # Development-only routes
  if Rails.env.development?
    namespace :dev do
      resources :users do
        member do
          post :switch
        end
      end
    end
  end
end
