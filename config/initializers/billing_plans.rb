# Central catalog for subscription plans used by the app
# Configure your Stripe Price IDs via environment/credentials and map them here.
# Example ENV variables (test):
#   STRIPE_PRICE_PRO_MONTHLY
#   STRIPE_PRICE_ENTERPRISE_MONTHLY
# Optional:
#   TRIAL_DAYS (integer)

module BillingPlans
  Plan = Struct.new(:key, :name, :env_price_key, :interval, :price_cents, keyword_init: true)

  CATALOG = [
    Plan.new(key: :pro_monthly,         name: "Pro",         env_price_key: "STRIPE_PRICE_PRO_MONTHLY",         interval: :month, price_cents: 2900),
    Plan.new(key: :enterprise_monthly,  name: "Enterprise",  env_price_key: "STRIPE_PRICE_ENTERPRISE_MONTHLY",  interval: :month, price_cents: 9900)
  ].freeze

  module_function

  def all
    CATALOG
  end

  def find(key)
    k = key.to_s
    CATALOG.find { |p| p.key.to_s == k }
  end

  def stripe_price_id_for(key)
    plan = find(key)
    return nil unless plan
    ENV[plan.env_price_key].presence || Rails.application.credentials.dig(:stripe, :prices, plan.key.to_s)
  end

  def trial_days
    (ENV["TRIAL_DAYS"].presence || Rails.application.credentials.dig(:subscriptions, :trial_days)).to_i.presence
  end

  def enabled?(key)
    stripe_price_id_for(key).present?
  end

  # Reverse lookup: given a Stripe Price ID, find the plan
  def plan_for_price_id(price_id)
    return nil unless price_id.present?
    CATALOG.find { |p| stripe_price_id_for(p.key).to_s == price_id.to_s }
  end
end

Rails.application.config.to_prepare do
  # Log plan availability at boot for easier setup
  BillingPlans.all.each do |plan|
    price_id = BillingPlans.stripe_price_id_for(plan.key)
    unless price_id.present?
      Rails.logger.warn("[BillingPlans] Missing Stripe Price ID for #{plan.key} (ENV #{plan.env_price_key} or credentials.stripe.prices.#{plan.key})")
    end
  end
end
