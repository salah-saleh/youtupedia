Rails.application.routes.draw do
  root "home#index"
  resources :summaries, only: [ :show ]
  resources :channels, only: [ :show ]
  get "/summaries", to: "summaries#show"
  get "/channels", to: "channels#show"
end
