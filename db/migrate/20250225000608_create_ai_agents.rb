class CreateAiAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_agents do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.text :instructions, null: false
      t.jsonb :tools, null: false, default: []

      t.timestamps
    end
  end
end
