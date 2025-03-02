class CreateAiMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_messages do |t|
      t.string :role
      t.text :content
      t.jsonb :tool_calls
      t.string :tool_call_id
      t.references :conversation, null: false, foreign_key: { to_table: :ai_conversations }

      t.timestamps
    end
  end
end
