Rails.application.routes.draw do
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
  get "pages/terms"
  get "pages/privacy"
  get "pages/dashboard"
  get "dashboard/:section", to: "pages#dashboard_section", as: :dashboard_section
  
  # Payment and subscription routes
  get "pricing", to: "subscriptions#pricing", as: :pricing
  
  resources :subscriptions do
    collection do
      get :success
      get :billing
      patch :update_billing_address
    end
  end
  
  resources :payments, only: [:index, :new, :create] do
    collection do
      get :success
    end
  end
  
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
  
  authenticate :user, -> user { user.admin?} do
    mount_avo
  end
  
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Hotwire::Spark::Engine => '/hotwire-spark'
  end

  # Payment method routes
  patch 'payment_methods/:id/set_default', to: 'payment_methods#set_default', as: 'set_default_payment_method'
  delete 'payment_methods/:id', to: 'payment_methods#destroy', as: 'delete_payment_method'
  post 'payment_methods', to: 'payment_methods#create', as: 'create_payment_method'

  # Subscription success route
  get 'subscriptions/success/:id', to: 'subscriptions#success', as: 'subscription_success'

  # Admin routes
  namespace :admin do
    resources :users
    resources :ai_agents
    resources :conversations
    resources :messages
    resources :subscriptions
    resources :payments
    
    root to: "users#index"
  end

  # Mount Pay routes
  # mount Pay::Engine, at: '/'

  resources :payment_methods, only: [:new, :create, :update, :destroy]

  post 'webhooks/stripe', to: 'webhooks#stripe'
end
