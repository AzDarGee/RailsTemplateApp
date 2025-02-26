class Ai::AgentTask < ApplicationRecord
  belongs_to :agent, class_name: "Ai::Agent"
  belongs_to :user
  belongs_to :parent_task, class_name: "Ai::AgentTask", optional: true

  has_many :messages, class_name: "Ai::AgentMessage", dependent: :destroy

  def upsert_message(message_params)
    existing = if message_params[:tool_calls].present?
      existing_tool_calls = messages.ordered.pluck(:id, :tool_calls)
      found = existing_tool_calls.select { |id, tool_calls| JSON.generate(tool_calls) == JSON.generate(message_params[:tool_calls]) }.first
      messages.find(found.first) if found.present?
    else
      messages.find_by(role: message_params[:role], content: message_params[:content], tool_call_id: message_params[:tool_call_id])
    end

    if existing.present?
      existing.update!(message_params)
    else
      messages.create!(message_params)
    end
  end
  
end
