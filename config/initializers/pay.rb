Pay.setup do |config|
  # For use in the receipt/refund/renewal mailers
  config.business_name = "Your App Name"
  config.business_address = "123 Business Street"
  config.application_name = "Your App Name"
  config.support_email = "support@example.com"

  config.default_product_name = "Your App Name"
  config.default_plan_name = "Monthly"

  config.automount_routes = true
  config.routes_path = "/pay"
  
  # All processors are enabled by default. If a processor is already implemented in your application, you can omit it from this list and the processor will not be set up through the Pay gem.
  config.enabled_processors = [:stripe]
end

# Stripe configuration
Rails.application.reloader.to_prepare do
  Pay::Stripe.setup do |stripe|
    stripe.public_key = Rails.application.credentials.dig(:stripe, :public_key)
    stripe.private_key = Rails.application.credentials.dig(:stripe, :private_key)
    stripe.signing_secret = Rails.application.credentials.dig(:stripe, :signing_secret)
    
    # To use Stripe Elements for card payments, you'll need to enable it in the initializer:
    stripe.elements = true
    
    # For more options, see the documentation:
    # https://github.com/pay-rails/pay/blob/master/docs/stripe/1_overview.md
  end
end 