class Ai::Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :agent, class_name: "Ai::Agent"
  has_many :messages, class_name: "Ai::Message", dependent: :destroy
end
