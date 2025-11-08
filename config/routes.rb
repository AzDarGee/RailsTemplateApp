Rails.application.routes.draw do
  resources :chats do
    resources :messages, only: [:create]
  end
  resources :models, only: [:index, :show] do
    collection do
      post :refresh
    end
  end
  root to: "pages#home"

  # If I need to customize devise controllers in the future
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    unlocks: "users/unlocks",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  post "/users/auth/:provider", to: "users/omniauth_callbacks#passthru", as: :user_omniauth_authorize

  get "pages/about"
  get "pages/contact"
  get "pages/pricing"
  get "pages/terms"
  get "pages/privacy"
  get "pages/refund_policy"

  # Billing portal (authenticated)
  authenticate :user do
    get   "billing",                     to: "billing#dashboard",        as: :billing_dashboard
    get   "billing/payment_methods",     to: "billing#payment_methods",  as: :billing_payment_methods
    post  "billing/setup_intent",        to: "billing#create_setup_intent", as: :billing_setup_intent
    post  "billing/attach_payment_method", to: "billing#attach_payment_method", as: :billing_attach_payment_method
    post  "billing/payment_methods/:id/default", to: "billing#set_default_payment_method", as: :billing_set_default_payment_method
    delete "billing/payment_methods/:id", to: "billing#detach_payment_method", as: :billing_detach_payment_method

    get   "billing/charges",             to: "billing#charges",          as: :billing_charges
    get   "billing/charges/:id/receipt", to: "billing#receipt",          as: :billing_receipt

    get   "billing/subscriptions",       to: "billing#subscriptions",    as: :billing_subscriptions
    post  "billing/subscribe",           to: "billing#subscribe",        as: :billing_subscribe
    post  "billing/subscriptions/:id/cancel", to: "billing#cancel_subscription", as: :billing_cancel_subscription
    post  "billing/subscriptions/:id/resume", to: "billing#resume_subscription", as: :billing_resume_subscription
    post  "billing/subscriptions/:id/swap",   to: "billing#swap_subscription",    as: :billing_swap_subscription

    # Stripe Checkout for subscriptions
    post  "billing/checkout",            to: "billing#checkout",          as: :billing_checkout
    get   "billing/checkout/success",   to: "billing#checkout_success",  as: :billing_checkout_success
    get   "billing/checkout/cancel",    to: "billing#checkout_cancel",   as: :billing_checkout_cancel
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => "/cable"
  mount MissionControl::Jobs::Engine, at: "/jobs"

  authenticate :user, ->(user) { user.admin? } do
    mount_avo
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
    mount Hotwire::Spark::Engine => "/hotwire-spark"
  end
end
