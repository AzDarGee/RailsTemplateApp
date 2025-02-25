class CreateAiAgentMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_agent_messages do |t|
      t.references :agent_task, null: false, foreign_key: { to_table: :ai_agent_tasks }
      t.string :role, null: false
      t.text :content
      t.jsonb :tool_calls
      t.string :tool_call_id

      t.timestamps
    end
  end
end
