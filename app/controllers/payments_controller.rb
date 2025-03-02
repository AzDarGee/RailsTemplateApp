class PaymentsController < ApplicationController
  before_action :authenticate_user!
  
  def new
    @payment_amount = params[:amount]
    @payment_description = params[:description] || "One-time payment"
  end
  
  def create
    # Create a one-time payment
    amount = (params[:amount].to_f * 100).to_i # Convert to cents
    description = params[:description] || "One-time payment"
    
    # Create a checkout session for the payment
    checkout_session = current_user.payment_processor.checkout(
      mode: "payment",
      line_items: [{
        name: description,
        amount: amount,
        currency: "usd",
        quantity: 1
      }],
      success_url: success_payments_url,
      cancel_url: new_payment_url
    )
    
    redirect_to checkout_session.url, allow_other_host: true
  end
  
  def success
    # Handle successful payment
    @payment = current_user.charges.order(created_at: :desc).first
    redirect_to root_path, notice: "Thank you for your payment!"
  end
  
  def index
    @payments = current_user.charges
  end
end 