class Ai::Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
end
