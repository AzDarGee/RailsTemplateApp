class Ai::AgentTask < ApplicationRecord
  belongs_to :agent, class_name: "Ai::Agent"
  belongs_to :user
  belongs_to :parent_task, class_name: "Ai::AgentTask", optional: true

  has_many :messages, class_name: "Ai::AgentMessage", dependent: :destroy
end
