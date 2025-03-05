class User < ApplicationRecord
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
