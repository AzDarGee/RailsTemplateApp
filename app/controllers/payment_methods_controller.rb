class PaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method, only: [:set_default, :destroy]

  def create
    # This would typically integrate with Stripe to create a payment method
    # For demonstration purposes, we'll simulate creating a payment method
    
    begin
      # In a real implementation, you would use the Stripe token to create a payment method
      # payment_method = current_user.create_payment_method(params[:stripe_token])
      
      # For demo purposes, we'll just redirect with a success message
      redirect_to billing_subscriptions_path, notice: "Payment method added successfully."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to add payment method: #{e.message}"
    end
  end

  def set_default
    begin
      # In a real implementation, you would update the default payment method in Stripe
      # @payment_method.set_as_default
      
      # For demo purposes, we'll just redirect with a success message
      redirect_to billing_subscriptions_path, notice: "Default payment method updated."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to update default payment method: #{e.message}"
    end
  end

  def destroy
    begin
      # In a real implementation, you would delete the payment method in Stripe
      # @payment_method.delete
      
      # For demo purposes, we'll just redirect with a success message
      redirect_to billing_subscriptions_path, notice: "Payment method removed."
    rescue => e
      redirect_to billing_subscriptions_path, alert: "Failed to remove payment method: #{e.message}"
    end
  end

  private

  def set_payment_method
    # In a real implementation, you would fetch the payment method from your database or Stripe
    # @payment_method = current_user.payment_methods.find(params[:id])
    
    # For demo purposes, we'll just set a dummy payment method
    @payment_method = OpenStruct.new(id: params[:id])
  end
end 