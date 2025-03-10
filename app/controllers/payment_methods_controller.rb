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
        # Use Stripe API directly to update the customer's default payment method
        Stripe::Customer.update(
          current_user.payment_processor.processor_id,
          { invoice_settings: { default_payment_method: payment_method.processor_id } }
        )
        
        # Refresh the payment processor to reflect changes
        # current_user.payment_processor.refresh
      end
      
      redirect_to billing_subscriptions_path, notice: "Payment method added successfully."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to add payment method: #{e.message}"
    end
  end

  def update
    # Make this payment method the default
    if params[:default] && @payment_method
      begin
        # Try different approaches to set default payment method
        Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
        
        # Use Stripe API directly to update the customer's default payment method
        Stripe::Customer.update(
          current_user.payment_processor.processor_id,
          { invoice_settings: { default_payment_method: @payment_method.processor_id } }
        )
        
        # Refresh the payment processor to reflect changes
        current_user.reload
        current_user.save
        
        redirect_to dashboard_section_path(section: "billing"), notice: "Default payment method updated."
      rescue => e
        Rails.logger.error("Failed to update default payment method: #{e.message}")
        redirect_to dashboard_section_path(section: "billing"), alert: "Failed to update payment method: #{e.message}"
      end
    else
      redirect_to dashboard_section_path(section: "billing"), alert: "Failed to update payment method."
    end
  end

  def destroy
    if @payment_method
      begin
        # Configure Stripe API key
        Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
        
        # Use Stripe API directly to detach the payment method
        Stripe::PaymentMethod.detach(@payment_method.processor_id)
        
        # Force reload of payment methods to clear cache
        current_user.reload
        
        # If using Pay gem's database records for payment methods, find and destroy the record
        if defined?(Pay::PaymentMethod)
          payment_method_record = Pay::PaymentMethod.find_by(processor_id: @payment_method.processor_id)
          payment_method_record.destroy if payment_method_record
        end
        
        redirect_to dashboard_section_path(section: "billing"), notice: "Payment method removed."
      rescue => e
        Rails.logger.error("Failed to remove payment method: #{e.message}")
        redirect_to dashboard_section_path(section: "billing"), alert: "Failed to remove payment method: #{e.message}"
      end
    else
      redirect_to dashboard_section_path(section: "billing"), alert: "Payment method not found."
    end
  end

  private

  def set_payment_method
    @payment_method = current_user.payment_processor.payment_methods.find_by(id: params[:id])
  end
end 