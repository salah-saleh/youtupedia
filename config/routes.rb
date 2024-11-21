Rails.application.routes.draw do
  root "home#index"
  resources :summaries, only: [ :show ]
end
