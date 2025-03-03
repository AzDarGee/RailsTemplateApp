# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create default plans
plans = [
  {
    name: 'Basic',
    price: 9.99,
    description: 'Perfect for getting started',
    features: 'Basic features, Email support, 1 project',
    popular: false,
    billing_frequency: 'monthly'
  },
  {
    name: 'Pro',
    price: 19.99,
    description: 'Best for growing businesses',
    features: 'All Basic features, Priority support, 5 projects, Advanced analytics',
    popular: true,
    billing_frequency: 'monthly'
  },
  {
    name: 'Enterprise',
    price: 49.99,
    description: 'For large scale operations',
    features: 'All Pro features, 24/7 support, Unlimited projects, Custom integrations',
    popular: false,
    billing_frequency: 'monthly'
  }
]

plans.each do |plan_attrs|
  Plan.find_or_create_by!(name: plan_attrs[:name]) do |plan|
    plan.attributes = plan_attrs
  end
end

puts "Created #{Plan.count} plans"
