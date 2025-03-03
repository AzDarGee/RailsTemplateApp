# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create initial plans
Plan.destroy_all

plans = [
  {
    name: 'Basic',
    price: 9.99,
    description: 'Perfect for individuals and small projects',
    features: 'Up to 3 projects, Basic support, 5GB storage',
    billing_frequency: 'monthly'
  },
  {
    name: 'Pro',
    price: 19.99,
    description: 'Great for professionals and growing teams',
    features: 'Unlimited projects, Priority support, 20GB storage, Advanced analytics',
    popular: true,
    billing_frequency: 'monthly'
  },
  {
    name: 'Enterprise',
    price: 49.99,
    description: 'For large organizations with advanced needs',
    features: 'Unlimited everything, 24/7 support, 100GB storage, Custom integrations, Dedicated account manager',
    billing_frequency: 'monthly'
  }
]

plans.each do |plan|
  Plan.create!(plan)
end

puts "Created #{Plan.count} plans"
