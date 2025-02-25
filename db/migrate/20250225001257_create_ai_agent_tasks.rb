class CreateAiAgentTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_agent_tasks do |t|
      t.references :agent, null: false, foreign_key: { to_table: :ai_agents }
      t.references :user, null: false, foreign_key: true
      t.references :parent_task, foreign_key: { to_table: :ai_agent_tasks }
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
