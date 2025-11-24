### High-level organization of the app
- Framework and stack
    - Ruby on Rails 8.1, Hotwire (Turbo + Stimulus), Devise for auth, Pay gem for payments (Stripe/Paddle), Active Storage, Action Text, Solid Queue/Cable/Cache, Avo for admin.
    - See `README.md` for the feature list:
      ```
      - Devise for authentication
      - Pay gem to manage payments (Stripe and PayPal)
      - SOLID Trifecta (Solid Queue, Cable, Cache)
      - AI Integration (LangChainRB)
      ```
- Key domains
    - Chat/AI: `Chat`, `Message`, `Model`, `ToolCall`, `ChatResponseJob`, controllers and Hotwire broadcasts.
    - Billing/Subscriptions: `BillingController` plus views under `app/views/billing`, pricing page, `Plan` model and `BillingPlans` initializer, Pay gem tables/models.
    - Users/Auth: `User` with Devise, OmniAuth, and Pay::Billable.

- Routing
    - `config/routes.rb` wires up chats, models, Devise, and the full billing portal:
      ```ruby
      resources :chats do
        resources :messages, only: [:create]
      end
      # ...
      authenticate :user do
        get   "billing", to: "billing#dashboard", as: :billing_dashboard
        get   "billing/payment_methods", to: "billing#payment_methods", as: :billing_payment_methods
        post  "billing/setup_intent", to: "billing#create_setup_intent", as: :billing_setup_intent
        post  "billing/attach_payment_method", to: "billing#attach_payment_method", as: :billing_attach_payment_method
        post  "billing/payment_methods/:id/default", to: "billing#set_default_payment_method", as: :billing_set_default_payment_method
        delete "billing/payment_methods/:id", to: "billing#detach_payment_method", as: :billing_detach_payment_method
        get   "billing/charges", to: "billing#charges", as: :billing_charges
        get   "billing/charges/:id/receipt", to: "billing#receipt", as: :billing_receipt
        get   "billing/subscriptions", to: "billing#subscriptions", as: :billing_subscriptions
        post  "billing/subscribe", to: "billing#subscribe", as: :billing_subscribe
        post  "billing/subscriptions/:id/cancel", to: "billing#cancel_subscription", as: :billing_cancel_subscription
        post  "billing/subscriptions/:id/resume", to: "billing#resume_subscription", as: :billing_resume_subscription
        post  "billing/subscriptions/:id/swap", to: "billing#swap_subscription", as: :billing_swap_subscription
        post  "billing/checkout", to: "billing#checkout", as: :billing_checkout
        get   "billing/checkout/success", to: "billing#checkout_success", as: :billing_checkout_success
        get   "billing/checkout/cancel", to: "billing#checkout_cancel", as: :billing_checkout_cancel
      end
      ```

### Data models and how they relate
- User
    - `app/models/user.rb` integrates Devise and Pay:
      ```ruby
      class User < ApplicationRecord
        devise :database_authenticatable, :registerable,
               :recoverable, :rememberable, :validatable,
               :confirmable, :lockable, :timeoutable, :trackable,
               :omniauthable, omniauth_providers: [ :google_oauth2, :linkedin, :facebook, :twitter2 ]
  
        pay_customer
        include Pay::Billable
        # ... ActionText bio, ActiveStorage avatar, and OmniAuth helper
      end
      ```
    - The Pay gem creates `Pay::Customer` records linked polymorphically to `User` and manages `pay_payment_methods`, `pay_subscriptions`, `pay_charges`.

- Chat and Message
    - `app/models/chat.rb` and `app/models/message.rb` use concerns that wire relationships and behavior (from a gem or internal concerns):
      ```ruby
      class Chat < ApplicationRecord
        acts_as_chat
      end
      ```
      ```ruby
      class Message < ApplicationRecord
        acts_as_message
        has_many_attached :attachments
        broadcasts_to ->(message) { "chat_#{message.chat_id}" }
        def broadcast_append_chunk(content)
          broadcast_append_to "chat_#{chat_id}",
            target: "message_#{id}_content",
            partial: "messages/content",
            locals: { content: content }
        end
      end
      ```
    - Schema shows the relations:
      ```ruby
      create_table "chats" do |t|
        t.bigint "model_id"
      end
      create_table "messages" do |t|
        t.bigint "chat_id", null: false
        t.bigint "model_id"
        t.bigint "tool_call_id"
        t.string "role", null: false
        # ... content, tokens, timestamps
      end
      ```
    - This implies: `Chat` has many `Message`s; a `Message` belongs to a `Chat`; messages may be associated to a `Model` and to a `ToolCall` by id; `role` distinguishes user/assistant/etc.

- Model (AI model catalog)
    - `app/models/model.rb` uses `acts_as_model` and the DB holds metadata for providers and pricing. From `db/schema.rb`:
      ```ruby
      create_table "models" do |t|
        t.string "provider", null: false
        t.string "model_id", null: false
        t.string "name", null: false
        t.jsonb "pricing", default: {}
        t.jsonb "capabilities", default: []
        t.jsonb "modalities", default: {}
        t.integer "context_window"
        t.integer "max_output_tokens"
        t.date "knowledge_cutoff"
        # indexes on provider/model_id, family, capabilities, etc.
      end
      ```
    - `ModelsController` exposes listing, details, and a `refresh` action:
      ```ruby
      class ModelsController < ApplicationController
        def index
          @models = Model.where(provider: "openrouter").limit(10)
        end
        def show
          @model = Model.find(params[:id])
        end
        def refresh
          Model.refresh!
          redirect_to models_path, notice: "Models refreshed successfully"
        end
      end
      ```

- ToolCall (function/tool invocation attached to a message)
    - `app/models/tool_call.rb`:
      ```ruby
      class ToolCall < ApplicationRecord
        acts_as_tool_call
      end
      ```
    - Schema:
      ```ruby
      create_table "tool_calls" do |t|
        t.string  "tool_call_id", null: false  # external id
        t.string  "name"
        t.jsonb   "arguments", default: {}
        t.jsonb   "result"
        t.bigint  "message_id", null: false    # owning message
      end
      add_foreign_key "tool_calls", "messages"
      ```
    - Messages render attached tool calls in `app/views/messages/_tool_calls.html.erb`.

- Plan (billing plans database-backed)
    - `app/models/plan.rb` stores catalog settings and delegates Stripe Price ID resolution to env/credentials:
      ```ruby
      class Plan < ApplicationRecord
        INTERVALS = %w[day week month year].freeze
        validates :key, presence: true, uniqueness: true
        validates :interval, presence: true, inclusion: { in: INTERVALS }
        scope :active, -> { where(active: true) }
        scope :ordered, -> { order(position: :asc, price_cents: :asc, name: :asc) }
        def stripe_price_id
          ENV[self.env_price_key].presence || self.credentials_price_id
        end
        # credentials_price_id reads credentials.stripe.prices[key]
      end
      ```

- Pay gem tables (payment data)
    - `db/schema.rb` includes:
      ```ruby
      create_table "pay_customers" do |t|
        t.string  "owner_type"  # typically "User"
        t.bigint  "owner_id"
        t.string  "processor"   # "stripe" or "paddle"
        t.string  "processor_id" # Stripe customer id
        t.jsonb   "data", "object"
      end
      create_table "pay_payment_methods" do |t|
        t.bigint  "customer_id", null: false
        t.string  "processor_id" # e.g., pm_xxx
        t.boolean "default"
      end
      create_table "pay_subscriptions" do |t|
        t.bigint  "customer_id", null: false
        t.string  "processor_id"
        t.string  "processor_plan" # Stripe price id (price_...)
        t.string  "status"
        t.datetime "current_period_end"
        t.datetime "trial_ends_at"
      end
      create_table "pay_charges" do |t|
        t.bigint  "customer_id", null: false
        t.bigint  "subscription_id"
        t.string  "processor_id"
        t.integer "amount"
        t.string  "currency"
      end
      ```

### Application flow: Chat/AI example
- Creating a message triggers a background job that streams model output via Turbo:
    - `app/controllers/messages_controller.rb`:
      ```ruby
      def create
        return unless content.present?
        ChatResponseJob.perform_later(@chat.id, content)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to @chat }
        end
      end
      ```
    - `app/jobs/chat_response_job.rb`:
      ```ruby
      def perform(chat_id, content)
        chat = Chat.find(chat_id)
        chat.ask(content) do |chunk|
          if chunk.content && !chunk.content.blank?
            message = chat.messages.last
            message.broadcast_append_chunk(chunk.content)
          end
        end
      end
      ```
    - `Message#broadcast_append_chunk` updates a specific message content target with partial `messages/content`.

### Payment portal: how it’s set up and works
- Foundations
    - `User` includes `Pay::Billable` and `pay_customer`, so each user gets a Pay customer for the configured processor (`stripe` or `paddle`).
    - Routes under `/billing/*` are behind `authenticate :user do ... end`.
    - `BillingPlans` initializer provides a simple catalog API backed by `Plan` records and resolves Stripe Price IDs from ENV or credentials:
      ```ruby
      module BillingPlans
        def all
          ::Plan.active.ordered
        end
        def stripe_price_id_for(key)
          find(key)&.stripe_price_id
        end
        def plan_for_price_id(price_id)
          all.find { |p| p.try(:stripe_price_id).to_s == price_id.to_s }
        end
      end
      ```

- Controller entry points (`app/controllers/billing_controller.rb`)
    - Guardrails and helpers:
      ```ruby
      before_action :authenticate_user!
      before_action :ensure_payment_processor!, only: [ :dashboard, :payment_methods, :create_setup_intent, :attach_payment_method,
        :detach_payment_method, :charges, :subscriptions, :subscribe, :cancel_subscription, :resume_subscription, :swap_subscription, :checkout ]
      helper_method :billing_stream_name, :billing_broadcast_updates
      ```
    - Dashboard: collects default payment method, recent charges, and subscriptions for the current user and renders Turbo-stream-friendly partials.
      ```ruby
      def dashboard
        @customer = current_user.payment_processor
        @default_payment_method = resolve_default_payment_method(@customer)
        @subscriptions = current_user.payment_processor&.subscriptions&.order(created_at: :desc) || []
        @charges = current_user.payment_processor&.charges&.order(created_at: :desc)&.limit(5) || []
      end
      ```
    - Payment methods page initializes Stripe.js client and handles add/remove/default logic.
        - Server side (`payment_methods`): determines Stripe publishable key and checks for mode mismatch to warn in UI.
          ```ruby
          def payment_methods
            @customer = current_user.payment_processor
            @payment_methods = current_user.payment_processor.payment_methods.order(created_at: :desc)
            @current_default_id = @customer&.default_payment_method&.id
            # If Stripe, fetch true default from Stripe invoice settings
            sc = Stripe::Customer.retrieve(@customer.processor_id)
            processor_default_pm = sc&.invoice_settings&.default_payment_method
            # ... set @current_default_id accordingly
            @stripe_public_key = Rails.application.credentials.dig(:stripe, :test, :public_key)
            # derive @stripe_key_mode vs @secret_key_mode and set @stripe_key_mismatch
          end
          ```
        - Client side view (`app/views/billing/payment_methods.html.erb`) mounts Stripe Elements and posts a SetupIntent and PaymentMethod id to the server:
          ```html
          <script src="https://js.stripe.com/v3/"></script>
          <script>
            const resp = await fetch('<%= billing_setup_intent_path %>', { method: 'POST' })
            const { client_secret } = await resp.json()
            const { setupIntent, error } = await stripe.confirmCardSetup(client_secret, { payment_method: { card }})
            // on success, POST setupIntent.payment_method to billing_attach_payment_method_path
          </script>
          ```
        - `create_setup_intent` server endpoint creates a Stripe SetupIntent bound to the user’s Stripe customer:
          ```ruby
          setup_intent = Stripe::SetupIntent.create({
            customer: current_user.payment_processor.processor_id,
            usage: "off_session",
            payment_method_types: ["card"]
          })
          render json: { client_secret: setup_intent.client_secret }
          ```
        - `attach_payment_method` receives `payment_method_id`, attaches it and enforces an app-side cap on number of saved cards:
          ```ruby
          if customer.payment_methods.count >= app_max_payment_methods
            # respond with alert; require removal first
          end
          # ... then set default if none or if explicitly chosen
          ```
        - `set_default_payment_method` updates the default both in Pay and, if Stripe, on the Stripe customer’s `invoice_settings.default_payment_method` for consistency.
        - `detach_payment_method` ensures you cannot detach the last/default method while active subscriptions require it.

    - Subscriptions management
        - Listing: `subscriptions` loads `@subscriptions` for the user; `billing/subscriptions.html.erb` renders a table partial with Turbo stream updates.
        - Creating: `subscribe` expects a `plan` key, resolves Stripe Price ID via `BillingPlans`, optionally sets trial days, and creates a Pay subscription. It also enforces `single active subscription` if configured:
          ```ruby
          plan_cfg = BillingPlans.find(plan_key)
          price_id = BillingPlans.stripe_price_id_for(plan_key)
          price_valid = BillingPlans.valid_stripe_price_id?(price_id)
          # ... create subscription via current_user.subscribe(name: ..., plan: price_id, trial_period_days: td)
          ```
        - Managing lifecycle: `cancel_subscription`, `resume_subscription`, `swap_subscription` call corresponding Pay gem operations and broadcast UI updates.

    - Checkout (Stripe Checkout flow)
        - `checkout` starts a checkout session for subscriptions (when enabled), and `checkout_success`/`checkout_cancel` handle redirects. The `pages/pricing.html.erb` links to start checkout or add a payment method:
          ```erb
          <%= button_to "Subscribe to #{bp.name}", billing_checkout_path(plan: bp.key), method: :post %>
          <%= button_to "Add Payment Method", billing_payment_methods_path, method: :get %>
          ```

    - Broadcasting updates
        - The controller defines helpers to Turbo-broadcast partial refreshes after mutating actions:
          ```ruby
          def billing_broadcast_updates(customer)
            broadcast_default_payment_method_card(customer)
            broadcast_subscriptions_list(customer)
            broadcast_recent_charges(customer)
          end
          ```
        - Views subscribe to the stream: in `billing/dashboard.html.erb`:
          ```erb
          <%= turbo_stream_from billing_stream_name %>
          ```

- Views and UX
    - Dashboard shows subscription status, default payment method, recent charges, with quick links to manage pages:
      ```erb
      <%= render partial: "billing/default_payment_method_card", locals: { default_payment_method: @default_payment_method } %>
      <%= render partial: "billing/recent_charges", locals: { charges: @charges } %>
      ```
    - Payment methods view shows card list, Stripe card entry, warnings for key mismatches, and disables the add button when at capacity.
    - Subscriptions view renders a table and offers a link back to pricing if none exist. Paddle portal link can be exposed via `ENV['PADDLE_CUSTOMER_PORTAL_URL']` when using Paddle.

### Concrete data relationships (summary)
- User has one-or-more Pay customers (via Pay::Billable); in this app, a single default `payment_processor` is used.
- Pay::Customer belongs to User (polymorphic). It has many `Pay::PaymentMethod`, `Pay::Subscription`, and `Pay::Charge`.
- Plan is the internal catalog; its `key` maps to Stripe `price_...` ids via ENV/credentials.
- Chat has many Message.
- Message belongs to Chat; may reference a Model (AI provider/model used) and a ToolCall (function call metadata) and includes `role` for who authored it.
- Model is metadata about AI models used for chats.
- ToolCall belongs to Message.

### Where to look to extend or debug
- Add or change plans: use `Plan` records and set environment variables matching `env_price_key` (e.g., `STRIPE_PRICE_PRO_MONTHLY`); `BillingPlans` logs missing price ids at boot.
- Stripe config: set `Rails.application.credentials.dig(:stripe, :test, :public_key)` and Stripe secret key (via `Stripe.api_key`). The payment methods page will warn on test/live mismatch.
- Subscription flows: start in `BillingController#subscribe` and `#swap_subscription`. Price resolution goes through `BillingPlans` and the `Plan#stripe_price_id` helper.
- Card flows: `create_setup_intent`, `attach_payment_method`, `set_default_payment_method`, `detach_payment_method`, and the Stripe.js UI in `app/views/billing/payment_methods.html.erb`.
- Chat streaming: `ChatResponseJob` and `Message#broadcast_append_chunk` drive Turbo updates; `MessagesController#create` enqueues the job.

### Example end-to-end: subscribing a user
1) User visits `/pages/pricing` where plans render from the `Plan` table through `BillingPlans` and can click a subscribe button:
   ```erb
   <% BillingPlans.all.each do |bp| %>
     <%= button_to "Subscribe to #{bp.name}", billing_checkout_path(plan: bp.key), method: :post %>
   <% end %>
   ```
2) `BillingController#checkout` or `#subscribe` resolves `plan` to a Stripe Price ID via `BillingPlans.stripe_price_id_for(plan_key)` and creates a Pay subscription (optionally with trials).
3) On success, the controller broadcasts updates so the dashboard immediately shows the subscription and default payment method.

If you want, I can map specific controller method paths to the exact Turbo partials they broadcast and sketch sequence diagrams for each flow (add card, set default, subscribe, swap).