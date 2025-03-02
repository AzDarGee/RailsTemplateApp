class Ai::Message < ApplicationRecord
  belongs_to :conversation, class_name: "Ai::Conversation"
end
