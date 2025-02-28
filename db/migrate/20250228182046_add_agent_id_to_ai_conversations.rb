class AddAgentIdToAiConversations < ActiveRecord::Migration[8.0]
  def change
    add_reference :ai_conversations, :agent, null: false, foreign_key: { to_table: :ai_agents }
  end
end
