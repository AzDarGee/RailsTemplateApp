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

  # Display price with currency; append interval suffix based on Stripe or catalog
  # Suffixes: /mo, /yr, /wk, /day
  def plan_display_price(plan_key, fallback_cents)
    price = stripe_price_for(plan_key)

    if price
      amount = (price.unit_amount || price.unit_amount_decimal).to_i
      interval = if price.respond_to?(:recurring) && price.recurring && price.recurring.respond_to?(:interval) && price.recurring.interval.present?
        price.recurring.interval.to_s
      else
        (BillingPlans.find(plan_key)&.interval.to_s.presence || "month")
      end
    else
      amount = fallback_cents.to_i
      interval = (BillingPlans.find(plan_key)&.interval.to_s.presence || "month")
    end

    suffix = case interval.to_s
             when "year" then "/yr"
             when "week" then "/wk"
             when "day"  then "/day"
             else "/mo"
             end

    "#{number_to_currency(amount / 100.0)} #{suffix}"
  end
end
