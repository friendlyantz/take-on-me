Rails.application.routes.draw do
  resources :challenge_stories, only: %i[index show new create edit update destroy]
  resources :challenge_participants, only: %i[create destroy]
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check
  mount Challenge::Engine, at: "/challenge"
  root "home#index"

  resource :session, only: [:new, :create, :destroy] do
    post :callback
  end

  resource :registration, only: [:new, :create] do
    post :callback
  end

  resources :credentials, only: [:index, :create, :destroy] do
    post :callback, on: :collection
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
