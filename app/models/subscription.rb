class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan
  
  validates :status, presence: true
  
  # You might want to add scopes for active/canceled subscriptions
  scope :active, -> { where(status: 'active') }
  scope :canceled, -> { where(status: 'canceled') }
end 