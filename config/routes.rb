Rails.application.routes.draw do
  root "home#index"

  resources :summaries, only: [ :show, :index ] do
    collection do
      get :create_from_url
      get :search
    end
    member do
      get :check_status
      post :ask_gpt
    end
  end

  resources :channels, only: [ :index, :show ] do
    collection do
      get :create_from_url
    end
  end
  post "/parse_youtube_url", to: "youtube_urls#parse"

  # Authentication routes
  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resources :passwords, param: :token

  # Email verification routes
  get "verify_email/:token", to: "email_verifications#verify", as: :verify_email
  post "resend_verification", to: "email_verifications#create", as: :resend_verification

  # Dev/Admin routes - available in all environments when accessed through settings
  namespace :dev do
    resources :users do
      member do
        post :switch
      end
    end
  end

  # Settings routes
  resource :settings, only: [ :show, :create ], controller: "settings" do
    get :index, on: :collection
  end

  resources :search, only: [ :index ] do
    collection do
      get :create_from_url
    end
  end

  # Static pages
  get "about", to: "pages#about"  
  get "contact", to: "pages#contact"
end

