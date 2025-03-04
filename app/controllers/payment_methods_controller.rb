class PaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method, only: [:set_default, :destroy]

  def create
    begin
      # Configure Stripe API key
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
      
      payment_method = current_user.payment_processor.add_payment_method(params[:payment_method_id])
      
      # Set as default if it's the first payment method
      if current_user.payment_processor.payment_methods.count == 1
        current_user.payment_processor.default_payment_method = payment_method
      end

      redirect_to billing_subscriptions_path, notice: "Payment method added successfully."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to add payment method: #{e.message}"
    end
  end

  def set_default
    begin
      current_user.payment_processor.default_payment_method = @payment_method
      redirect_to billing_subscriptions_path, notice: "Default payment method updated."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to update default payment method: #{e.message}"
    end
  end

  def destroy
    begin
      @payment_method.delete
      redirect_to billing_subscriptions_path, notice: "Payment method removed."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to remove payment method: #{e.message}"
    end
  end

  private

  def set_payment_method
    @payment_method = current_user.payment_processor.payment_methods.find { |m| m.id == params[:id] }
    unless @payment_method
      redirect_to billing_subscriptions_path, alert: "Payment method not found."
      return
    end
  end
end 