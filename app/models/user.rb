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
    subscription.present? && subscription.active?
  end

  def subscription
    subscriptions.active.first
  end

  def subscription_name
    subscription&.name || 'No Subscription'
  end

  def subscription_price
    subscription&.processor_plan || 0
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
end
