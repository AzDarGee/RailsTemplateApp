class BillingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_payment_processor!, only: [
    :dashboard,
    :payment_methods,
    :create_setup_intent,
    :attach_payment_method,
    :detach_payment_method,
    :charges,
    :subscriptions,
    :subscribe,
    :cancel_subscription,
    :resume_subscription,
    :swap_subscription,
    :checkout
  ]

  helper_method :billing_stream_name
  helper_method :billing_broadcast_updates
  helper PagesHelper

  def dashboard
    @customer = current_user.payment_processor
    @default_payment_method = resolve_default_payment_method(@customer)
    @subscriptions = current_user.payment_processor&.subscriptions&.order(created_at: :desc) || []
    @active_subscription = @subscriptions.detect { |s| s.status === "active" }

    
    # binding.pry_remote
    @charges = current_user.payment_processor&.charges&.order(created_at: :desc)&.limit(5) || []
  end

  def payment_methods
    @customer = current_user.payment_processor
    @payment_methods = current_user.payment_processor.payment_methods.order(created_at: :desc)
    @payment_methods_count = @payment_methods.size
    @app_max_payment_methods = app_max_payment_methods
    @at_payment_method_cap = @payment_methods_count >= @app_max_payment_methods

    # Determine the current default payment method id for deterministic badge rendering
    @current_default_id = @customer&.default_payment_method&.id
    if using_stripe?
      begin
        sc = Stripe::Customer.retrieve(@customer.processor_id)
        processor_default_pm = sc&.invoice_settings&.default_payment_method
        if processor_default_pm.present?
          pm = @payment_methods.find { |m| m.processor_id == processor_default_pm }
          @current_default_id = pm.id if pm
        end
      rescue => e
        Rails.logger.warn("[Billing#payment_methods] Unable to fetch Stripe default payment method: #{e.class} #{e.message}")
      end
    end

    @stripe_public_key = Rails.application.credentials.dig(:stripe, :test, :public_key)

    # Detect potential key mode mismatches that can cause 400 errors on confirmation
    secret_key = (defined?(Stripe) && Stripe.respond_to?(:api_key)) ? Stripe.api_key : nil
    @stripe_key_mode = if @stripe_public_key.to_s.start_with?("pk_live_")
      "live"
    elsif @stripe_public_key.to_s.start_with?("pk_test_")
      "test"
    end
    @secret_key_mode = if secret_key.to_s.start_with?("sk_live_")
      "live"
    elsif secret_key.to_s.start_with?("sk_test_")
      "test"
    end
    @stripe_key_mismatch = @stripe_key_mode.present? && @secret_key_mode.present? && (@stripe_key_mode != @secret_key_mode)
  end

  # Returns JSON with a client_secret for Stripe SetupIntent
  def create_setup_intent
    unless using_stripe?
      return render json: { error: "Card management is only available for Stripe accounts." }, status: :unprocessable_entity
    end

    setup_intent = Stripe::SetupIntent.create({
      customer: current_user.payment_processor.processor_id,
      usage: "off_session",
      payment_method_types: ["card"]
    })

    render json: { client_secret: setup_intent.client_secret }
  rescue => e
    Rails.logger.error("[Billing#create_setup_intent] #{e.class}: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Attaches a Stripe payment method to the user and sets it as default
  def attach_payment_method
    unless using_stripe?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Card management is only available for Stripe accounts." }) }
        format.html { redirect_to billing_payment_methods_path, alert: "Card management is only available for Stripe accounts." }
      end
      return
    end

    payment_method_id = params[:payment_method_id].presence
    unless payment_method_id
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Missing payment method. Please try adding your card again." }) }
        format.html { redirect_to billing_payment_methods_path, alert: "Missing payment method. Please try adding your card again." }
      end
      return
    end

    customer = current_user.payment_processor

    # App-side safeguard: enforce a configurable max number of saved cards
    if customer.payment_methods.count >= app_max_payment_methods
      msg = "You have #{@payment_methods&.size || customer.payment_methods.count} saved cards, which meets the application limit (#{app_max_payment_methods}). Please remove an existing card and try again."
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: msg }) }
        format.html { redirect_to billing_payment_methods_path, alert: msg }
      end
      return
    end

    # Attach on Stripe + persist locally (creates/updates a Pay::PaymentMethod record)
    customer.add_payment_method(payment_method_id)

    # Resolve the newly attached payment method record from our DB
    pm_record = customer.payment_methods.find_by(processor_id: payment_method_id)
    unless pm_record
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Unable to set the default card. Please try again." }) }
        format.html { redirect_to billing_payment_methods_path, alert: "Unable to set the default card. Please try again." }
      end
      return
    end

    # Set as default on Stripe via Pay and ensure persistence
    begin
      customer.default_payment_method = pm_record
      if defined?(Stripe)
        # Ensure Stripe customer has the default set at the API level
        Stripe::Customer.update(customer.processor_id, invoice_settings: { default_payment_method: pm_record.processor_id })
      end
    rescue => e
      Rails.logger.warn("[Billing#attach_payment_method] Failed to set default: #{e.class} #{e.message}")
    end

    # Reload customer/payment methods so pm.default? reflects the latest default
    customer.reload if customer.respond_to?(:reload)

    # Auto-subscribe to intended plan if present in session
    if session[:intended_plan].present?
      plan_key = session.delete(:intended_plan)
      plan_cfg = BillingPlans.find(plan_key)
      price_id = BillingPlans.stripe_price_id_for(plan_key)
      price_valid = BillingPlans.valid_stripe_price_id?(price_id)
      if plan_cfg
        begin
          existing_any = customer.subscriptions.order(created_at: :desc).detect { |s| (s.respond_to?(:active?) && s.active?) || %w[active trialing].include?(s.status.to_s) }
          if existing_any
            if price_valid
              # Swap existing active/trialing to intended plan to keep single active subscription
              if existing_any.processor_plan.to_s != price_id.to_s
                if existing_any.respond_to?(:swap)
                  existing_any.swap(price_id)
                else
                  Stripe::Subscription.update(existing_any.processor_id, { items: [{ price: price_id }], proration_behavior: "create_prorations" })
                  existing_any.reload if existing_any.respond_to?(:reload)
                end
              end
              # Ensure name reflects the plan even when swapping an existing subscription
              begin
                existing_any.update(name: plan_cfg.name)
              rescue => e
                Rails.logger.warn("[Billing#attach_payment_method] Failed to set subscription name: #{e.class} #{e.message}")
              end
              @auto_subscribed_plan_name = plan_cfg.name
            else
              # Can't swap without a valid Price ID
              Rails.logger.info("[Billing#attach_payment_method] Intended plan has no valid Stripe Price ID; skipping swap.")
            end
          else
            if price_valid
              args = { name: plan_cfg.name, plan: price_id, quantity: 1 }
              td = BillingPlans.trial_days
              args[:trial_period_days] = td if td && td > 0
              customer.subscribe(**args)
              @auto_subscribed_plan_name = plan_cfg.name
            else
              # No existing subscription: use Stripe Checkout (with price_data fallback) to create subscription
              return start_checkout_for_plan!(plan_key)
            end
          end
        rescue => e
          Rails.logger.warn("[Billing#attach_payment_method] Auto-subscribe failed: #{e.class} #{e.message}")
        end
      end
    end

    @payment_methods = customer.payment_methods.order(created_at: :desc)
    @payment_methods_count = @payment_methods.size
    @app_max_payment_methods = app_max_payment_methods
    @at_payment_method_cap = @payment_methods_count >= @app_max_payment_methods

    # Resolve deterministic current default id (Stripe source of truth)
    default_id = resolve_current_default_id(customer, @payment_methods)

    # Broadcast Dashboard updates (default card, subscriptions list, recent charges)
    billing_broadcast_updates(customer)

    notice_msg = @auto_subscribed_plan_name.present? ? "Card added and set as default. Subscribed to #{@auto_subscribed_plan_name}." : "Card added and set as default."

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "payment_methods_list",
            partial: "billing/payment_methods_list",
            locals: { payment_methods: @payment_methods, just_default_id: pm_record.id, current_default_id: default_id }
          ),
          turbo_stream.update(
            "payment_methods_meta",
            partial: "billing/payment_methods_meta",
            locals: { payment_methods_count: @payment_methods_count, app_max_payment_methods: @app_max_payment_methods, at_payment_method_cap: @at_payment_method_cap }
          ),
          turbo_stream.update(
            "flash",
            partial: "shared/flash_messages",
            locals: { notice: notice_msg }
          )
        ]
      end
      format.html { redirect_to billing_payment_methods_path, notice: notice_msg }
    end
  rescue => e
    # Provide a friendlier message when Stripe's hard cap on payment methods is reached
    message = e.message.to_s
    friendly = message

    if (
      defined?(Stripe) && e.is_a?(Stripe::InvalidRequestError) &&
      e.respond_to?(:code) && ["resource_limit_exceeded", "payment_method_limit_exceeded", "customer_max_payment_methods"].include?(e.code.to_s)
    ) || message.match?(/maximum number of payment methods/i)
      friendly = "This customer has reached Stripe’s maximum number of saved cards. Please remove an existing card and try again."
    end

    Rails.logger.warn("[Billing#attach_payment_method] Attach failed: #{e.class} code=#{e.respond_to?(:code) ? e.code : nil} message=#{message}")

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: friendly }) }
      format.html { redirect_to billing_payment_methods_path, alert: friendly }
    end
  end

  # Detach a payment method (Stripe) and remove its local record
  def detach_payment_method
    unless using_stripe?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Card management is only available for Stripe accounts." }) }
        format.html { redirect_to billing_payment_methods_path, alert: "Card management is only available for Stripe accounts." }
      end
      return
    end

    payment_method = current_user.payment_processor.payment_methods.find(params[:id])
    was_default = payment_method.respond_to?(:default?) ? payment_method.default? : payment_method.default
    modal_id = "delete-pm-#{payment_method.id}-modal"

    # 1) Detach from Stripe (remote)
    payment_method.detach

    # 2) Remove local DB record as well
    begin
      payment_method.destroy!
    rescue => e
      Rails.logger.warn("[Billing#detach_payment_method] Local destroy failed: #{e.class} #{e.message}")
    end

    # 3) If the removed method was default, pick another one as default if available; otherwise clear default on Stripe
    promoted_id = nil
    if was_default
      # Prefer newest card (DESC) to align with display order
      next_pm = current_user.payment_processor.payment_methods.order(created_at: :desc).first
      if next_pm.present?
        # Set the AR record as the new default (Pay v11 accepts a Pay::PaymentMethod object)
        begin
          current_user.payment_processor.default_payment_method = next_pm
          promoted_id = next_pm.id
          if defined?(Stripe)
            Stripe::Customer.update(current_user.payment_processor.processor_id, invoice_settings: { default_payment_method: next_pm.processor_id })
          end
        rescue => e
          Rails.logger.warn("[Billing#detach_payment_method] Failed to promote next default: #{e.class} #{e.message}")
        end
      else
        # Explicitly clear default on Stripe when none remain
        begin
          if defined?(Stripe)
            Stripe::Customer.update(current_user.payment_processor.processor_id, invoice_settings: { default_payment_method: nil })
          end
        rescue => e
          Rails.logger.warn("[Billing#detach_payment_method] Failed to clear default on Stripe: #{e.class} #{e.message}")
        end
      end
    end

    # Reload processor so default? flags are up-to-date
    current_user.payment_processor.reload if current_user.payment_processor.respond_to?(:reload)

    @payment_methods = current_user.payment_processor.payment_methods.order(created_at: :desc)
    @payment_methods_count = @payment_methods.size
    @app_max_payment_methods = app_max_payment_methods
    @at_payment_method_cap = @payment_methods_count >= @app_max_payment_methods

    # Resolve deterministic current default id (Stripe source of truth)
    default_id = resolve_current_default_id(current_user.payment_processor, @payment_methods)

    # Broadcast Dashboard card update
    broadcast_default_payment_method_card(current_user.payment_processor)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "payment_methods_list",
            partial: "billing/payment_methods_list",
            locals: { payment_methods: @payment_methods, current_default_id: default_id, just_default_id: promoted_id }
          ),
          turbo_stream.update(
            "payment_methods_meta",
            partial: "billing/payment_methods_meta",
            locals: { payment_methods_count: @payment_methods_count, app_max_payment_methods: @app_max_payment_methods, at_payment_method_cap: @at_payment_method_cap }
          ),
          turbo_stream.update(
            "flash",
            partial: "shared/flash_messages",
            locals: { notice: "Payment method removed." }
          )
        ]
      end
      format.html { redirect_to billing_payment_methods_path, notice: "Payment method removed." }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Payment method not found." }) }
      format.html { redirect_to billing_payment_methods_path, alert: "Payment method not found." }
    end
  rescue => e
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
      format.html { redirect_to billing_payment_methods_path, alert: e.message }
    end
  end

  def charges
    @charges = current_user.payment_processor.charges.order(created_at: :desc)
  end

  def subscriptions
    @subscriptions = current_user.payment_processor.subscriptions.order(created_at: :desc)
  end

  # Create a subscription for the current user to a given plan (Stripe via Pay)
  def subscribe
    unless using_stripe?
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Subscriptions are only available for Stripe accounts." }) }
        format.html { redirect_to billing_dashboard_path, alert: "Subscriptions are only available for Stripe accounts." }
      end
    end

    plan_key = params[:plan].to_s.presence
    plan_cfg = BillingPlans.find(plan_key)
    price_id = BillingPlans.stripe_price_id_for(plan_key)
    price_valid = BillingPlans.valid_stripe_price_id?(price_id)

    unless plan_cfg
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Selected plan is not available. Please try again later." }) }
        format.html { redirect_to pages_pricing_path, alert: "Selected plan is not available. Please try again later." }
      end
    end

    customer = current_user.payment_processor

    # For direct subscription (without Checkout), ensure a default payment method exists.
    if price_valid && resolve_default_payment_method(customer).blank?
      # Remember intended plan and redirect to add a card
      session[:intended_plan] = plan_key
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Add a default payment method to continue your subscription." }) }
        format.html { redirect_to billing_payment_methods_path, alert: "Add a default payment method to continue your subscription." }
      end
    end

    # Enforce single active subscription: swap existing active/trialing (not on grace) if present, otherwise create new
    existing_any = customer.subscriptions.order(created_at: :desc).detect do |s|
      status = s.status.to_s
      active_like = (s.respond_to?(:active?) && s.active?) || %w[active trialing].include?(status)
      on_grace = (s.respond_to?(:on_grace_period?) && s.on_grace_period?)
      active_like && !on_grace
    end

    # If there is no valid Stripe Price ID configured, fallback:
    unless price_valid
      if existing_any
        return respond_to do |format|
          msg = "Selected plan isn't fully configured yet for direct changes. Please cancel your current subscription, then subscribe via Checkout from the Pricing page."
          format.html { redirect_to billing_subscriptions_path, alert: msg }
          format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: msg }) }
        end
      else
        # No existing subscription: use Stripe Checkout (with price_data fallback) to create
        return start_checkout_for_plan!(plan_key)
      end
    end

    if existing_any
      if existing_any.processor_plan.to_s == price_id.to_s
        return respond_to do |format|
          format.html { redirect_to billing_dashboard_path, notice: "You are already on the #{plan_cfg.name} plan." }
          format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { notice: "You are already on the #{plan_cfg.name} plan." }) }
        end
      else
        begin
          if existing_any.respond_to?(:swap)
            existing_any.swap(price_id)
          else
            Stripe::Subscription.update(existing_any.processor_id, { items: [{ price: price_id }], proration_behavior: "create_prorations" })
            existing_any.reload if existing_any.respond_to?(:reload)
          end
          # Ensure local name reflects the chosen plan
          begin
            existing_any.update(name: plan_cfg.name)
          rescue => e
            Rails.logger.warn("[Billing#subscribe] Failed to set subscription name: #{e.class} #{e.message}")
          end
        rescue => e
          Rails.logger.warn("[Billing#subscribe] Swap existing failed: #{e.class} #{e.message}")
          return respond_to do |format|
            format.html { redirect_to billing_subscriptions_path, alert: e.message }
            format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
          end
        end

        # Recompute for views and broadcasts
        @subscriptions = customer.subscriptions.order(created_at: :desc)
        @charges = customer.charges.order(created_at: :desc).limit(5)
        broadcast_subscriptions_list(customer)
        broadcast_recent_charges(customer)

        return respond_to do |format|
          format.html { redirect_to billing_subscriptions_path, notice: "Plan changed to #{plan_cfg.name}." }
          format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { notice: "Plan changed to #{plan_cfg.name}." }) }
        end
      end
    end

    args = { name: plan_cfg.name, plan: price_id, quantity: 1 }
    td = BillingPlans.trial_days
    args[:trial_period_days] = td if td && td > 0

    subscription = customer.subscribe(**args)

    # Recompute for views and broadcasts
    @subscriptions = customer.subscriptions.order(created_at: :desc)
    @charges = customer.charges.order(created_at: :desc).limit(5)

    # Broadcast Dashboard updates
    broadcast_subscriptions_list(customer)
    broadcast_recent_charges(customer)

    respond_to do |format|
      format.html { redirect_to billing_dashboard_path, notice: "Subscribed to #{plan_cfg.name}." }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("flash", partial: "shared/flash_messages", locals: { notice: "Subscribed to #{plan_cfg.name}." })
        ]
      end
    end
  rescue => e
    Rails.logger.warn("[Billing#subscribe] Failed: #{e.class} #{e.message}")
    respond_to do |format|
      format.html { redirect_to pages_pricing_path, alert: e.message }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
    end
  end

  def cancel_subscription
    sub = current_user.payment_processor.subscriptions.find(params[:id])
    sub.cancel

    customer = current_user.payment_processor
    @subscriptions = customer.subscriptions.order(created_at: :desc)
    @charges = customer.charges.order(created_at: :desc).limit(5)

    broadcast_subscriptions_list(customer)
    broadcast_recent_charges(customer)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "billing_subscriptions_table",
            partial: "billing/subscriptions_table",
            locals: { subscriptions: @subscriptions }
          ),
          turbo_stream.update(
            "flash",
            partial: "shared/flash_messages",
            locals: { notice: "Subscription will cancel at period end." }
          )
        ]
      end
      format.html { redirect_to billing_subscriptions_path, notice: "Subscription will cancel at period end." }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to billing_subscriptions_path, alert: "Subscription not found." }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Subscription not found." }) }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to billing_subscriptions_path, alert: e.message }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
    end
  end

  def resume_subscription
    sub = current_user.payment_processor.subscriptions.find(params[:id])
    if sub.respond_to?(:on_grace_period?) && sub.on_grace_period?
      sub.resume
      # Ensure single active after resume
      enforce_single_active_subscription!(current_user.payment_processor, keep_processor_id: sub.processor_id)
      msg = "Subscription resumed."
    else
      msg = "Subscription cannot be resumed."
    end

    customer = current_user.payment_processor
    @subscriptions = customer.subscriptions.order(created_at: :desc)
    @charges = customer.charges.order(created_at: :desc).limit(5)

    broadcast_subscriptions_list(customer)
    broadcast_recent_charges(customer)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "billing_subscriptions_table",
            partial: "billing/subscriptions_table",
            locals: { subscriptions: @subscriptions }
          ),
          turbo_stream.update(
            "flash",
            partial: "shared/flash_messages",
            locals: { notice: msg }
          )
        ]
      end
      format.html { redirect_to billing_subscriptions_path, notice: msg }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to billing_subscriptions_path, alert: "Subscription not found." }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Subscription not found." }) }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to billing_subscriptions_path, alert: e.message }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
    end
  end

  # Stripe Checkout for Subscriptions
  # Creates a Checkout Session and redirects the user to Stripe-hosted page.
  def checkout
    plan_key = params[:plan].to_s.presence
    return start_checkout_for_plan!(plan_key)
  end

  # After successful Stripe Checkout
  def checkout_success
    # After returning from Stripe Checkout, best-effort sync of local subscription so it appears in the UI
    keep_processor_id = nil
    begin
      if params[:session_id].present? && defined?(Stripe)
        sess = Stripe::Checkout::Session.retrieve(params[:session_id])

        if sess.respond_to?(:subscription) && sess.subscription.present?
          stripe_sub = Stripe::Subscription.retrieve(sess.subscription)
          keep_processor_id = stripe_sub.id

          customer = current_user.payment_processor
          if stripe_sub.customer.to_s == customer.processor_id.to_s
            # Map first subscription item for plan/quantity
            item = (stripe_sub.items&.data || []).first
            price_id = (item&.respond_to?(:price) && item.price) ? item.price.id : (item&.respond_to?(:plan) ? item.plan&.id : nil)
            quantity = item&.quantity || 1
            plan = BillingPlans.plan_for_price_id(price_id.to_s)

            local = customer.subscriptions.find_by(processor_id: stripe_sub.id)
            attrs = {
              name: (plan&.name || price_id.to_s),
              processor_plan: price_id.to_s,
              quantity: quantity,
              status: stripe_sub.status.to_s,
              current_period_start: (Time.at(stripe_sub.current_period_start).to_datetime rescue nil),
              current_period_end: (Time.at(stripe_sub.current_period_end).to_datetime rescue nil),
              trial_ends_at: (stripe_sub.trial_end ? Time.at(stripe_sub.trial_end).to_datetime : nil),
              ends_at: (stripe_sub.cancel_at ? Time.at(stripe_sub.cancel_at).to_datetime : nil)
            }

            if local
              local.update(attrs)
            else
              customer.subscriptions.create!(attrs.merge(processor_id: stripe_sub.id))
            end

            # Enforce single active/trialing subscription by canceling others
            enforce_single_active_subscription!(customer, keep_processor_id: keep_processor_id)
          else
            Rails.logger.warn("[Billing#checkout_success] Customer mismatch: session subscription customer #{stripe_sub.customer} != current #{customer.processor_id}")
          end
        end
      end
    rescue => e
      Rails.logger.warn("[Billing#checkout_success] Sync from Stripe failed: #{e.class} #{e.message}")
    end

    customer = current_user.payment_processor
    @subscriptions = customer.subscriptions.order(created_at: :desc)
    @charges = customer.charges.order(created_at: :desc).limit(5)

    billing_broadcast_updates(customer)

    redirect_to billing_dashboard_path, notice: "Checkout complete. Your subscription is active or pending activation."
  end

  def checkout_cancel
    redirect_to pages_pricing_path, alert: "Checkout was canceled. No changes were made."
  end

  # Upgrade/Downgrade (swap) subscription plan with proration
  def swap_subscription
    sub = current_user.payment_processor.subscriptions.find(params[:id])

    plan_key = params[:plan].to_s.presence
    plan_cfg = BillingPlans.find(plan_key)
    price_id = BillingPlans.stripe_price_id_for(plan_key)
    price_valid = BillingPlans.valid_stripe_price_id?(price_id)

    unless plan_cfg
      return respond_to do |format|
        format.html { redirect_to billing_subscriptions_path, alert: "Selected plan is not available." }
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Selected plan is not available." }) }
      end
    end

    unless price_valid
      msg = "Selected plan isn't fully configured for direct plan changes. Please cancel your current subscription, then subscribe to #{plan_cfg.name} via Checkout from the Pricing page."
      return respond_to do |format|
        format.html { redirect_to billing_subscriptions_path, alert: msg }
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: msg }) }
      end
    end

    if sub.processor_plan.to_s == price_id.to_s
      msg = "You are already on the #{plan_cfg.name} plan."
    else
      # Rely on Pay to update the Stripe subscription with proration
      begin
        if sub.respond_to?(:swap)
          sub.swap(price_id)
        else
          # Fallback: direct Stripe update (best-effort)
          Stripe::Subscription.update(sub.processor_id, {
            items: [{ price: price_id }],
            proration_behavior: "create_prorations"
          })
          sub.reload if sub.respond_to?(:reload)
        end
        msg = "Plan changed to #{plan_cfg.name}."
      rescue => e
        Rails.logger.warn("[Billing#swap_subscription] Swap failed: #{e.class} #{e.message}")
        return respond_to do |format|
          format.html { redirect_to billing_subscriptions_path, alert: e.message }
          format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
        end
      end
    end

    customer = current_user.payment_processor
    @subscriptions = customer.subscriptions.order(created_at: :desc)
    @charges = customer.charges.order(created_at: :desc).limit(5)

    broadcast_subscriptions_list(customer)
    broadcast_recent_charges(customer)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "billing_subscriptions_table",
            partial: "billing/subscriptions_table",
            locals: { subscriptions: @subscriptions }
          ),
          turbo_stream.update(
            "flash",
            partial: "shared/flash_messages",
            locals: { notice: msg }
          )
        ]
      end
      format.html { redirect_to billing_subscriptions_path, notice: msg }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to billing_subscriptions_path, alert: "Subscription not found." }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Subscription not found." }) }
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to billing_subscriptions_path, alert: e.message }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
    end
  end

  # Set a payment method as the default for the current user (Stripe)
  # Turbo Streams: replaces payment_methods_list and payment_methods_meta, updates flash, and passes just_default_id for client-side highlight.
  def set_default_payment_method
    unless using_stripe?
      @default_payment_method = current_user.payment_processor.default_payment_method
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Card management is only available for Stripe accounts." }) }
        format.html { redirect_to billing_payment_methods_path, alert: "Card management is only available for Stripe accounts." }
      end
      return
    end

    customer = current_user.payment_processor
    payment_method = customer.payment_methods.find(params[:id])

    # Set as default using Pay API (accepts AR record) and ensure Stripe invoice_settings is updated
    begin
      customer.default_payment_method = payment_method
      if defined?(Stripe)
        Stripe::Customer.update(customer.processor_id, invoice_settings: { default_payment_method: payment_method.processor_id })
      end
    rescue => e
      Rails.logger.warn("[Billing#set_default_payment_method] Failed to set default: #{e.class} #{e.message}")
    end

    # Reload to ensure pm.default? reflects latest state
    customer.reload if customer.respond_to?(:reload)

    @payment_methods = customer.payment_methods.order(created_at: :desc)
    @payment_methods_count = @payment_methods.size
    @app_max_payment_methods = app_max_payment_methods
    @at_payment_method_cap = @payment_methods_count >= @app_max_payment_methods

    # Resolve deterministic current default id (Stripe source of truth)
    default_id = resolve_current_default_id(customer, @payment_methods)

    # Broadcast Dashboard card update
    broadcast_default_payment_method_card(customer)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
            "payment_methods_list",
            partial: "billing/payment_methods_list",
            locals: { payment_methods: @payment_methods, just_default_id: payment_method.id, current_default_id: default_id }
          ),
          turbo_stream.update(
            "payment_methods_meta",
            partial: "billing/payment_methods_meta",
            locals: { payment_methods_count: @payment_methods_count, app_max_payment_methods: @app_max_payment_methods, at_payment_method_cap: @at_payment_method_cap }
          ),
          turbo_stream.update(
            "flash",
            partial: "shared/flash_messages",
            locals: { notice: "Default payment method updated." }
          )
        ]
      end
      format.html { redirect_to billing_payment_methods_path, notice: "Default payment method updated." }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Payment method not found." }) }
      format.html { redirect_to billing_payment_methods_path, alert: "Payment method not found." }
    end
  rescue => e
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
      format.html { redirect_to billing_payment_methods_path, alert: e.message }
    end
  end

  # Download receipt PDF for a charge
  def receipt
    charge = current_user.payment_processor.charges.find(params[:id])
    receipt = charge.receipt(
      product: "Rails Template App",
      company: "Saanskara Studios",
      email: current_user.email,
      address: "Ottawa, ON, Canada",
      phone: "+1 613 613 1234",
      logo: current_user.avatar.url
    )

    send_data receipt.render, filename: "receipt-#{charge.id}.pdf", type: "application/pdf", disposition: "inline"
  rescue ActiveRecord::RecordNotFound
    redirect_to billing_charges_path, alert: "Charge not found."
  rescue => e
    redirect_to billing_charges_path, alert: e.message
  end

  private

  # Cancel all active/trialing subscriptions for this customer except the one with processor_id == keep_processor_id
  def enforce_single_active_subscription!(customer, keep_processor_id: nil)
    return unless customer
    begin
      subs = customer.subscriptions.order(created_at: :desc)
      subs.each do |s|
        next if keep_processor_id.present? && s.processor_id.to_s == keep_processor_id.to_s
        status = s.status.to_s
        active_like = (s.respond_to?(:active?) && s.active?) || status == 'active' || status == 'trialing'
        next unless active_like
        begin
          # Prefer cancel at period end to avoid surprising immediate termination
          s.cancel
        rescue => e
          Rails.logger.warn("[Billing#enforce_single_active_subscription!] Failed to cancel subscription #{s.id}: #{e.class} #{e.message}")
        end
      end
    rescue => e
      Rails.logger.warn("[Billing#enforce_single_active_subscription!] Error: #{e.class} #{e.message}")
    end
  end

  def ensure_payment_processor!
    return if current_user.payment_processor.present?

    preferred = preferred_processor
    current_user.set_payment_processor(preferred)
  end

  # Broadcast helper to update dashboard sections commonly affected by billing changes
  def billing_broadcast_updates(customer)
    broadcast_subscriptions_list(customer)
    broadcast_recent_charges(customer)
    # Keep default card panel in sync if needed
    broadcast_default_payment_method_card(customer)
  end

  def preferred_processor
    if Rails.application.credentials.dig(:stripe, :test, :private_key).present?
      :stripe
    elsif Rails.application.credentials.dig(:paddle, :test, :private_key).present?
      :paddle
    else
      :stripe
    end
  end

  # Configurable application-side maximum for saved payment methods.
  # Defaults to 10 if not set via APP_MAX_PAYMENT_METHODS env var.
  def app_max_payment_methods
    val = ENV["APP_MAX_PAYMENT_METHODS"].to_i
    val > 0 ? val : 10
  end

  def using_stripe?
    current_user.payment_processor.processor.to_s == "stripe"
  end

  # Stream name for per-user billing updates
  def billing_stream_name
    "billing_user_#{current_user.id}"
  end

  # Determine current default payment method id, preferring Stripe's invoice_settings.default_payment_method
  def resolve_current_default_id(customer, payment_methods)
    return nil unless customer && payment_methods

    default_id = customer.default_payment_method&.id

    if using_stripe?
      begin
        sc = Stripe::Customer.retrieve(customer.processor_id)
        processor_default_pm = sc&.invoice_settings&.default_payment_method
        if processor_default_pm.present?
          mapped = payment_methods.find { |m| m.processor_id == processor_default_pm }
          default_id = mapped.id if mapped
        end
      rescue => e
        Rails.logger.warn("[Billing#resolve_current_default_id] Unable to fetch Stripe default payment method: #{e.class} #{e.message}")
      end
    end

    default_id
  end

  # Broadcast Dashboard default payment method card update to the current user
  # Use `update` so the wrapper div#default_payment_method_card remains in the DOM for subsequent updates
  def broadcast_default_payment_method_card(customer)
    begin
      Turbo::StreamsChannel.broadcast_update_later_to(
        billing_stream_name,
        target: "default_payment_method_card",
        partial: "billing/default_payment_method_card",
        locals: { default_payment_method: resolve_default_payment_method(customer) }
      )
    rescue => e
      Rails.logger.warn("[Billing#broadcast_default_payment_method_card] Broadcast failed: #{e.class} #{e.message}")
    end
  end

  # Resolve the current default payment method object for display on the Dashboard.
  # Prefers local Pay::PaymentMethod, but consults Stripe's invoice_settings.default_payment_method
  # and falls back to a lightweight presenter when the local record is missing.
  def resolve_default_payment_method(customer)
    return nil unless customer.present?

    local_pm = customer.default_payment_method

    # If not using Stripe, rely on local state (e.g., Paddle not supported here)
    return local_pm unless using_stripe?

    begin
      sc = Stripe::Customer.retrieve(customer.processor_id)
      processor_default_pm = sc&.invoice_settings&.default_payment_method
      return local_pm unless processor_default_pm.present?

      # Try to map Stripe processor_id -> local Pay::PaymentMethod
      mapped = customer.payment_methods.find_by(processor_id: processor_default_pm)
      return mapped if mapped.present?

      # Fallback: fetch from Stripe and build a lightweight presenter
      require 'ostruct'
      spm = Stripe::PaymentMethod.retrieve(processor_default_pm)
      card = spm.respond_to?(:card) ? spm.card : nil
      brand = card&.brand
      last4 = card&.last4
      pm_type = spm&.type || 'card'
      OpenStruct.new(brand: brand, payment_method_type: pm_type, last4: last4)
    rescue => e
      Rails.logger.warn("[Billing#resolve_default_payment_method] Unable to resolve default via Stripe: #{e.class} #{e.message}")
      local_pm
    end
  end

  # Start Stripe Checkout for the given plan key, using a configured Stripe Price ID when valid,
  # or falling back to price_data (currency/unit_amount/interval) when no valid price is configured.
  # Performs the redirect to Stripe-hosted Checkout and returns.
  def start_checkout_for_plan!(plan_key)
    unless using_stripe?
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Stripe Checkout is only available for Stripe accounts." }) }
        format.html { redirect_to pages_pricing_path, alert: "Stripe Checkout is only available for Stripe accounts." }
      end
    end

    plan_cfg = BillingPlans.find(plan_key)
    unless plan_cfg
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: "Selected plan is not available." }) }
        format.html { redirect_to pages_pricing_path, alert: "Selected plan is not available." }
      end
    end

    customer = current_user.payment_processor

    # Prevent creating a second concurrent subscription via Checkout
    existing_any = customer.subscriptions.order(created_at: :desc).detect do |s|
      status = s.status.to_s
      active_like = (s.respond_to?(:active?) && s.active?) || %w[active trialing].include?(status)
      on_grace = (s.respond_to?(:on_grace_period?) && s.on_grace_period?)
      active_like && !on_grace
    end
    if existing_any
      msg = "You already have an active subscription. Use 'Change plan' to switch."
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { notice: msg }) }
        format.html { redirect_to billing_subscriptions_path, notice: msg }
      end
    end

    price_id = BillingPlans.stripe_price_id_for(plan_key)

    line_item = if BillingPlans.valid_stripe_price_id?(price_id)
      { price: price_id, quantity: 1 }
    else
      {
        price_data: {
          currency: "usd",
          product_data: { name: plan_cfg.name },
          unit_amount: plan_cfg.price_cents,
          recurring: { interval: plan_cfg.interval.to_s }
        },
        quantity: 1
      }
    end

    params_hash = {
      mode: "subscription",
      customer: customer.processor_id,
      payment_method_types: ["card"],
      line_items: [ line_item ],
      allow_promotion_codes: true,
      success_url: billing_checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: billing_checkout_cancel_url
    }

    td = BillingPlans.trial_days
    if td && td > 0
      params_hash[:subscription_data] = { trial_period_days: td }
    end

    sess = Stripe::Checkout::Session.create(params_hash)

    # Store recent intent for UX if desired
    begin
      session[:plan] = plan_key
    rescue => _e
    end

    redirect_to sess.url, allow_other_host: true, status: :see_other
  rescue => e
    Rails.logger.warn("[Billing#start_checkout_for_plan!] Failed: #{e.class} #{e.message}")
    respond_to do |format|
      format.html { redirect_to pages_pricing_path, alert: e.message }
      format.turbo_stream { render turbo_stream: turbo_stream.update("flash", partial: "shared/flash_messages", locals: { alert: e.message }) }
    end
  end

  # Broadcast: update dashboard subscriptions list
  def broadcast_subscriptions_list(customer)
    Turbo::StreamsChannel.broadcast_update_later_to(
      billing_stream_name,
      target: "subscriptions_list",
      partial: "billing/subscriptions_list",
      locals: { subscriptions: customer.subscriptions.order(created_at: :desc).first(5) }
    )
  rescue => e
    Rails.logger.warn("[Billing#broadcast_subscriptions_list] Broadcast failed: #{e.class} #{e.message}")
  end

  # Broadcast: update dashboard recent charges
  def broadcast_recent_charges(customer)
    Turbo::StreamsChannel.broadcast_update_later_to(
      billing_stream_name,
      target: "recent_charges",
      partial: "billing/recent_charges",
      locals: { charges: customer.charges.order(created_at: :desc).limit(5) }
    )
  rescue => e
    Rails.logger.warn("[Billing#broadcast_recent_charges] Broadcast failed: #{e.class} #{e.message}")
  end
end
