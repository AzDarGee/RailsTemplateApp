class User < ApplicationRecord
  # Include Pay's billable concern
  include Pay::Billable

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

  # Validations
  validates :email, disposable_email: true
  
  # Billing address fields
  attr_accessor :billing_name, :billing_email, :billing_address, :billing_city, 
                :billing_state, :billing_zip, :billing_country
  
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

  # Check if user has an active subscription
  def subscribed?
    # In a real implementation, you would check if the user has an active subscription
    # return subscriptions.active.exists?
    
    # For demo purposes, we'll just return false
    false
  end
  
  # Get the user's active subscription
  def subscription
    # In a real implementation, you would return the user's active subscription
    # return subscriptions.active.first
    
    # For demo purposes, we'll just return a dummy subscription
    OpenStruct.new(
      id: SecureRandom.uuid,
      name: ['Basic', 'Pro', 'Enterprise'].sample,
      processor: 'stripe',
      processor_id: "sub_#{SecureRandom.hex(10)}",
      processor_plan: ['basic', 'pro', 'enterprise'].sample,
      quantity: 1,
      status: 'active',
      trial_ends_at: nil,
      ends_at: 1.month.from_now
    )
  end
  
  # Get the user's payment history
  def charges
    # In a real implementation, you would return the user's payment history
    # return payment_processor.charges
    
    # For demo purposes, we'll just return an empty array
    []
  end
  
  # Get the user's payment methods
  def payment_methods
    # In a real implementation, you would return the user's payment methods
    # return payment_processor.payment_methods
    
    # For demo purposes, we'll just return an empty array
    []
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
