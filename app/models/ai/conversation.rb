class Ai::Conversation < ApplicationRecord
  belongs_to :user
  belongs_to :agent, class_name: "Ai::Agent"
  has_many :messages, class_name: "Ai::Message", dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
      ["id", "title", "category"]
  end

  def self.ransackable_associations(auth_object = nil)
      ["messages", "user", "agent"]
  end

end
