json.extract! ai_conversation, :id, :title, :category, :user_id, :created_at, :updated_at
json.url ai_conversation_url(ai_conversation, format: :json)
