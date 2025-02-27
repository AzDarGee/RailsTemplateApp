class Ai::AgentMessage < ApplicationRecord
  belongs_to :agent_task, class_name: "Ai::AgentTask"

  scope :ordered, -> { order(created_at: :asc) }

  after_create_commit do
    broadcast_append_to(
      "agent_task_#{agent_task_id}",
      target: "agent_task_#{agent_task_id}_messages",
      html: ApplicationController.renderer.render(MessageComponent.new(message: self), layout: false)
    )
  end

  after_update_commit do
    broadcast_replace_to(
      "agent_task_#{agent_task_id}",
      target: "agent_task_#{agent_task_id}_message_#{id}",
      html: ApplicationController.renderer.render(MessageComponent.new(message: self), layout: false)
    )
  end

end
