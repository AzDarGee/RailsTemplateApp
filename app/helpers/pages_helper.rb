module PagesHelper
  # Fetch and cache Stripe Price for a plan key
  def stripe_price_for(plan_key)
    price_id = BillingPlans.stripe_price_id_for(plan_key)
    return nil unless price_id.present? && defined?(Stripe)

    Rails.cache.fetch("stripe_price:#{price_id}", expires_in: 15.minutes) do
      Stripe::Price.retrieve(price_id)
    end
  rescue => e
    Rails.logger.warn("[PagesHelper#stripe_price_for] Failed to fetch price for #{plan_key}: #{e.class} #{e.message}")
    nil
  end

  # Display price with currency; fall back to catalog cents and USD
  def plan_display_price(plan_key, fallback_cents)
    price = stripe_price_for(plan_key)
    if price
      amount = (price.unit_amount || price.unit_amount_decimal).to_i
      currency = price.currency.to_s.upcase
      "#{number_to_currency(amount / 100.0)} /mo"
    else
      "#{number_to_currency(fallback_cents.to_i / 100.0)} /mo"
    end
  end
end
