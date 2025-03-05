class User < ApplicationRecord
  # Include Pay's billable concern and set default processor
  include Pay::Billable
  pay_customer default_payment_processor: :stripe

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2, :linkedin, :facebook, :twitter2]

  has_many :agents, class_name: "Ai::Agent", dependent: :destroy
  has_many :conversations, class_name: "Ai::Conversation", dependent: :destroy

  has_rich_text :bio
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [400, 400], preprocessed: true
  end

  # Subscription methods
  def subscribed?
    payment_processor&.subscriptions&.active&.any?
  end

  def subscription
    payment_processor&.subscriptions&.active&.first
  end

  def subscription_name
    return 'No Subscription' unless subscription
    
    # Use Pay's data attribute which contains the plan information
    subscription.name || 'Unknown Plan'
  end

  def subscription_price
    return 0 unless subscription
    
    # Use Pay's data attribute which contains the price information
    begin
      # The amount is stored in cents, so divide by 100 to get dollars
      subscription.data.dig('amount', 'amount') / 100.0
    rescue
      # Fallback to getting it from Stripe directly if needed
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :test, :private_key)
      stripe_sub = Stripe::Subscription.retrieve({
        id: subscription.processor_id,
        expand: ['items.data.price']
      })
      
      stripe_sub.items.data.first.price.unit_amount / 100.0
    rescue => e
      Rails.logger.error("Error retrieving subscription price: #{e.message}")
      0
    end
  end

  # Validations
  validates :email, disposable_email: true
  
  # Billing address fields
  # These fields already exist in the database, so we don't need attr_accessor
  
  # Update billing address information
  def update_billing_address(params)
    update(
      billing_name: params[:billing_name],
      billing_email: params[:billing_email],
      billing_address: params[:billing_address],
      billing_city: params[:billing_city],
      billing_state: params[:billing_state],
      billing_zip: params[:billing_zip],
      billing_country: params[:billing_country]
    )
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email || "#{auth.uid}@twitter.example"
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.image = auth.info.image
      
      # Skip confirmation if using confirmable
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["id", "email", "name", "username"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["agents", "conversations"]
  end
end
