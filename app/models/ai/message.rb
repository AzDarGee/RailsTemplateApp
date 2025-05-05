class Ai::Message < ApplicationRecord
  belongs_to :conversation, class_name: "Ai::Conversation"

  def self.ransackable_attributes(auth_object = nil)
      [ "id", "role", "content" ]
  end

  def self.ransackable_associations(auth_object = nil)
      [ "conversation" ]
  end
end
