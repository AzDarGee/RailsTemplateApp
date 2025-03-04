class PaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method, only: [:update, :destroy]

  def new
    # Configure Stripe API key
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
    
    # Create a setup intent
    @setup_intent = Stripe::SetupIntent.create(
      customer: current_user.payment_processor.processor_id,
      payment_method_types: ['card']
    )
    
    # Set client secret for the view
    @client_secret = @setup_intent.client_secret
  end

  def create
    begin
      # Configure Stripe API key
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
      
      # Add the payment method to the customer
      payment_method = current_user.payment_processor.add_payment_method(params[:payment_method_id])
      
      # Set as default if it's the first payment method
      if current_user.payment_processor.payment_methods.count == 1
        current_user.payment_processor.update_default_payment_method(payment_method.processor_id)
      end
      
      redirect_to billing_subscriptions_path, notice: "Payment method added successfully."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to add payment method: #{e.message}"
    end
  end

  def update
    # Make this payment method the default
    if params[:default] && @payment_method
      current_user.payment_processor.update_default_payment_method(@payment_method.processor_id)
      redirect_to billing_subscriptions_path, notice: "Default payment method updated."
    else
      redirect_to billing_subscriptions_path, alert: "Failed to update payment method."
    end
  end

  def destroy
    if @payment_method
      current_user.payment_processor.delete_payment_method(@payment_method.processor_id)
      redirect_to billing_subscriptions_path, notice: "Payment method removed."
    else
      redirect_to billing_subscriptions_path, alert: "Failed to remove payment method."
    end
  end

  private

  def set_payment_method
    @payment_method = current_user.payment_processor.payment_methods.find_by(id: params[:id])
  end
end 