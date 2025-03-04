class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)
    
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      render json: { error: e.message }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: e.message }, status: 400
      return
    end
    
    # Handle the event
    case event.type
    when 'customer.subscription.created', 'customer.subscription.updated'
      subscription = event.data.object
      user = Pay::Customer.find_by(processor_id: subscription.customer)&.owner
      
      if user
        # Update any custom fields or perform any actions needed
        # For example, update user's role based on subscription
      end
    when 'customer.subscription.deleted'
      subscription = event.data.object
      user = Pay::Customer.find_by(processor_id: subscription.customer)&.owner
      
      if user
        # Handle subscription cancellation
        # For example, downgrade user's role
      end
    end
    
    render json: { received: true }
  end
end 