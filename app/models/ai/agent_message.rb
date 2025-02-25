class Ai::AgentMessage < ApplicationRecord
  belongs_to :agent_task, class_name: "Ai::AgentTask"

  scope :ordered, -> { order(created_at: :asc) }
end
