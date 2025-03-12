class RemoveAiAgentTasksAndMessagesTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :ai_agent_messages
    drop_table :ai_agent_tasks
  end
end
