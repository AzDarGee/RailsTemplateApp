Rails.application.routes.draw do
  mount_avo
  root to: "pages#home"
  
  # If I need to customize devise controllers in the future
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations',
    unlocks: 'users/unlocks',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  post '/users/auth/:provider', to: 'users/omniauth_callbacks#passthru', as: :user_omniauth_authorize
  
  get "pages/about"
  get "pages/contact"
  get "pages/pricing"

  namespace :ai do   
    resources :agents do
      resources :conversations do
        resources :messages
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => '/cable'
  mount MissionControl::Jobs::Engine, at: "/jobs"
  
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Hotwire::Spark::Engine => '/hotwire-spark'
  end
end
