# Seed essential application data (idempotent)

begin
  if ActiveRecord::Base.connection.table_exists?(:plans)
    plans = [
      { key: :starter_monthly,    name: "Starter",    env_price_key: "STRIPE_PRICE_STARTER_MONTHLY",    interval: "month", price_cents: 900,  active: true, position: 1 },
      { key: :pro_monthly,        name: "Pro",        env_price_key: "STRIPE_PRICE_PRO_MONTHLY",        interval: "month", price_cents: 2900, active: true, position: 2 },
      { key: :enterprise_monthly, name: "Enterprise", env_price_key: "STRIPE_PRICE_ENTERPRISE_MONTHLY", interval: "month", price_cents: 9900, active: true, position: 3 }
    ]

    plans.each do |attrs|
      record = Plan.find_or_initialize_by(key: attrs[:key])
      record.assign_attributes(attrs)
      record.save! if record.changed?
    end

    puts "Seeded Plans (#{Plan.count})"
  end
rescue => e
  puts "[seeds] Skipped plans seeding: #{e.class} #{e.message}"
end
