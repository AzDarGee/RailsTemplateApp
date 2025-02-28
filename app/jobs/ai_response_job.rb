class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(ai_message_id, ai_conversation_id)
    message = Message.find(ai_message_id)
    conversation = Conversation.find(ai_conversation_id)
    
    # Simulate AI processing time
    sleep(1)
    
    # In a real app, you would call your AI service here
    ai_response = "This is a sample response from the AI agent #{conversation.agent.name}."
    
    # Update the message with the real response
    message.update(content: ai_response)
    
    # Broadcast the updated message to all clients
    Turbo::StreamsChannel.broadcast_replace_to(
      "conversation_#{conversation.id}",
      target: "message_#{message.id}",
      partial: "ai/messages/message",
      locals: { message: message }
    )
  end
end
