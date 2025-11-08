class BillingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_payment_processor!, only: [
    :dashboard,
    :payment_methods,
    :create_setup_intent,
    :attach_payment_method,
    :detach_payment_method,
    :charges,
    :subscriptions
  ]

  helper_method :billing_stream_name

  def dashboard
    @customer = current_user.payment_processor
    @default_payment_method = current_user.payment_processor&.default_payment_method
    @subscriptions = current_user.payment_processor&.subscriptions&.order(created_at: :desc) || []
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
            locals: { notice: "Card added and set as default." }
          )
        ]
      end
      format.html { redirect_to billing_payment_methods_path, notice: "Card added and set as default." }
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

  def ensure_payment_processor!
    return if current_user.payment_processor.present?

    preferred = preferred_processor
    current_user.set_payment_processor(preferred)
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
  def broadcast_default_payment_method_card(customer)
    begin
      Turbo::StreamsChannel.broadcast_replace_later_to(
        billing_stream_name,
        target: "default_payment_method_card",
        partial: "billing/default_payment_method_card",
        locals: { default_payment_method: customer&.default_payment_method }
      )
    rescue => e
      Rails.logger.warn("[Billing#broadcast_default_payment_method_card] Broadcast failed: #{e.class} #{e.message}")
    end
  end
end
