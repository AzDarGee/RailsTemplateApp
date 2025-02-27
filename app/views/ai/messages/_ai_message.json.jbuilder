json.extract! ai_message, :id, :role, :content, :tool_calls, :tool_call_id, :conversation_id, :created_at, :updated_at
json.url ai_message_url(ai_message, format: :json)
