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

  # Unified subscription status presentation for views.
  # Returns [status_text, badge_class]
  # - If the subscription is set to cancel at period end (grace period),
  #   show "canceling" with a warning badge.
  # - Otherwise, map known statuses to consistent badge colors.
  def subscription_status_and_badge(sub)
    raw_status = sub.respond_to?(:status) ? sub.status.to_s : ""

    if sub.respond_to?(:on_grace_period?) && sub.on_grace_period?
      return ["canceling", "bg-warning"]
    end

    badge_class = case raw_status
                  when "active" then "bg-success"
                  when "trialing" then "bg-info"
                  when "past_due" then "bg-warning"
                  when "canceled", "unpaid", "incomplete_expired" then "bg-secondary"
                  else "bg-secondary"
                  end

    [raw_status, badge_class]
  end
end
