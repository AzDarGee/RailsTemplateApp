# Central catalog for subscription plans used by the app
# Now backed by the database (Plan model). Configure Stripe Price IDs via ENV or credentials.
# Example ENV variables (test):
#   STRIPE_PRICE_STARTER_MONTHLY
#   STRIPE_PRICE_PRO_MONTHLY
#   STRIPE_PRICE_ENTERPRISE_MONTHLY
# Optional:
#   TRIAL_DAYS (integer)

module BillingPlans
  module_function

  # Simple validation for a Stripe Price ID. Accepts strings starting with "price_".
  def valid_stripe_price_id?(price_id)
    price_id.to_s.start_with?("price_")
  end

  # Returns a list-like collection of active plans ordered for presentation.
  # Safe when DB/table is unavailable (e.g., before migrations): returns [].
  def all
    plan_scope
  rescue NameError, ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
    []
  end

  # Find plan by symbolic or string key. Returns a Plan record or nil.
  def find(key)
    k = key.to_s
    all.find { |p| p.key.to_s == k }
  end

  # Resolve the Stripe Price ID for a plan key using ENV first, then credentials.
  def stripe_price_id_for(key)
    plan = find(key)
    plan&.stripe_price_id
  rescue => _e
    nil
  end

  # Trial days can be configured via ENV or credentials.
  def trial_days
    ((ENV["TRIAL_DAYS"].presence || credentials_dig(:subscriptions, :trial_days)).to_i).presence
  rescue => _e
    nil
  end

  def enabled?(key)
    stripe_price_id_for(key).present?
  end

  # Reverse lookup: given a Stripe Price ID, find the plan.
  def plan_for_price_id(price_id)
    return nil unless price_id.present?
    all.find { |p| p.try(:stripe_price_id).to_s == price_id.to_s }
  rescue => _e
    nil
  end

  # --- helpers ---
  def plan_scope
    # Avoid constant lookup at load time; only access Plan inside methods
    ::Plan.active.ordered
  end

  def credentials_dig(*path)
    Rails.application.credentials.dig(*path)
  rescue => _e
    nil
  end
end

Rails.application.config.to_prepare do
  # Log plan availability at boot for easier setup, but be tolerant pre‑migrate.
  begin
    plans = BillingPlans.all
    if plans.empty?
      Rails.logger.info("[BillingPlans] No plans found yet. Run migrations and seed the database.")
    else
      plans.each do |plan|
        price_id = BillingPlans.stripe_price_id_for(plan.key)
        unless price_id.present?
          Rails.logger.warn("[BillingPlans] Missing Stripe Price ID for #{plan.key} (ENV #{plan.env_price_key} or credentials.stripe.prices.#{plan.key})")
        end
      end
    end
  rescue => _e
    # Ignore errors (e.g., DB not ready) to not block boot in other environments
  end
end
