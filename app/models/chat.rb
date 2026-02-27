class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :user

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "messages", "model" ]
  end

  def self.ransackable_associations(auth_object = nil)
    # [ "agents", "conversations" ]
  end
end
