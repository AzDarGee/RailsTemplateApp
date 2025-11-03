RubyLLM.configure do |config|
  config.openrouter_api_key = Rails.application.credentials.dig(:ai, :open_router, :api_key)
  # config.default_model = "gpt-4.1-nano"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
