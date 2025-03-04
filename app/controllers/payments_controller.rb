class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stripe_key
  
  def new
    @payment_amount = params[:amount]
    @payment_description = params[:description] || "One-time payment"
  end
  
  def create
    # Create a one-time payment
    amount = (params[:amount].to_f * 100).to_i # Convert to cents
    description = params[:description] || "One-time payment"
    
    # Create a checkout session for the payment using Pay gem
    checkout_session = current_user.payment_processor.checkout(
      mode: "payment",
      line_items: [{
        price_data: {
          currency: "usd",
          product_data: {
            name: description
          },
          unit_amount: amount
        },
        quantity: 1
      }],
      success_url: success_payments_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: new_payment_url,
      metadata: {
        description: description
      }
    )
    
    redirect_to checkout_session.url, allow_other_host: true
  end
  
  def success
    begin
      # Retrieve the checkout session from Stripe
      session_id = params[:session_id]
      
      if session_id.present?
        # Retrieve the session
        session = Stripe::Checkout::Session.retrieve(session_id)
        
        if session.payment_status == 'paid' && session.payment_intent.present?
          # Get the payment intent ID
          payment_intent_id = session.payment_intent
          
          # Check if we already have this charge
          existing_charge = current_user.charges.find_by(processor_id: payment_intent_id)
          
          unless existing_charge
            # Get the payment intent
            payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
            
            # Get the charges directly
            charges = Stripe::Charge.list({payment_intent: payment_intent_id})
            
            # Get receipt URL if available
            receipt_url = nil
            charge_created_at = nil
            if charges.data.any?
              stripe_charge = charges.data.first
              receipt_url = stripe_charge.receipt_url
              charge_created_at = Time.at(stripe_charge.created)
            end
            
            # Create the charge record
            charge = current_user.payment_processor.charges.create!(
              amount: payment_intent.amount,
              currency: payment_intent.currency,
              processor_id: payment_intent_id,
              created_at: charge_created_at,
              metadata: {
                description: session.metadata&.description || "One-time payment"
              },
              data: {
                status: payment_intent.status,
                receipt_url: receipt_url,
                created_at: charge_created_at&.to_i
              }
            )
            
            @payment = charge
          else
            @payment = existing_charge
          end
        end
      else
        # Fallback to the old method if no session_id is provided
        @payment = current_user.charges.order(created_at: :desc).first
      end
      
      redirect_to payments_path, notice: "Thank you for your payment!"
    rescue => e
      Rails.logger.error("Payment Error: #{e.message}\n#{e.backtrace.join("\n")}")
      redirect_to payments_path, alert: "There was an issue processing your payment: #{e.message}"
    end
  end
  
  def index
    # Get all payment types
    @charges = current_user.charges.order(created_at: :desc)
    @subscriptions = current_user.subscriptions.order(created_at: :desc)
    
    # Combine all payment types into a single collection
    @payments = @charges + @subscriptions
    
    # Sort by created_at in descending order
    @payments = @payments.sort_by(&:created_at).reverse
  end
  
  private
  
  def set_stripe_key
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
  end
end 