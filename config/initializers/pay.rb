# Pay / Stripe / Paddle configuration
# Set your environment variables in credentials or environment:
# - STRIPE_SECRET_KEY (or STRIPE_API_KEY)
# - STRIPE_PUBLIC_KEY (aka publishable)
# - PADDLE_API_KEY (and PADDLE_CUSTOMER_PORTAL_URL if you expose a customer portal)
# - Optional: APP_NAME, BUSINESS_NAME, BUSINESS_ADDRESS, BUSINESS_PHONE, BUSINESS_LOGO_URL, SUPPORT_EMAIL

Rails.application.config.to_prepare do
  # Stripe
  key = (
    Rails.application.credentials.dig(:stripe, :test, :private_key)
  )

  if key.present?
    require "stripe"
    Stripe.api_key = key
  end
end

Pay.setup do |config|
  config.application_name = "Rails Template App"
  config.support_email = "contact@saanskara.studio"
  # Use the Receipts gem defaults via `charge.receipt` in controller
  # You can set business details here or pass them to `charge.receipt` options.
  config.business_address = "Ottawa, ON, Canada"

  # Do not automount any engine paths (we manage our own routes/views)
  if config.respond_to?(:automount_paths=)
    config.automount_paths = false
  end

  # Emails are optional; Pay provides mailers if configured
  if config.respond_to?(:send_emails=)
    config.send_emails = true
  end
end
