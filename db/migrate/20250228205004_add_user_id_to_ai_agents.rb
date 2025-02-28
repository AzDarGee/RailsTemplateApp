class AddUserIdToAiAgents < ActiveRecord::Migration[8.0]
  def change
    add_reference :ai_agents, :user, null: false, foreign_key: { to_table: :users }
  end
end
