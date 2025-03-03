Pay.setup do |config|
  # For use in the receipt/refund/renewal mailers
  config.business_name = "Saanskara Studios"
  config.business_address = "Ottawa, Ontario, Canada"
  config.application_name = "RailsTemplateApp"
  config.support_email = "saanskarastudios@gmail.com"

  config.default_product_name = "RailsTemplateApp"
  config.default_plan_name = "Monthly"

  config.automount_routes = true
  config.routes_path = "/pay"
  
  # All processors are enabled by default. If a processor is already implemented in your application, you can omit it from this list and the processor will not be set up through the Pay gem.
  config.enabled_processors = [:stripe]
end

# Stripe configuration
Rails.application.reloader.to_prepare do
  Pay::Stripe.setup do |stripe|
    # Load Stripe API keys
    stripe.public_key = Rails.application.credentials.dig(:stripe, :test, :public_key)
    stripe.private_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
    stripe.signing_secret = Rails.application.credentials.dig(:stripe, :test, :signing_secret)
    
    # Configure Stripe directly as well
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
    
    # To use Stripe Elements for card payments
    stripe.elements = true
    
    # Set default currency
    stripe.currency = 'usd'
  end
end 