class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id, conversation_id)
    message = Ai::Message.find(message_id)
    conversation = Ai::Conversation.find(conversation_id)
    
    # Get the agent associated with this conversation
    agent = conversation.agent
    
    begin
      # In a real app, you would call your AI service here
      ai_response = "This is a sample response from the AI agent #{agent.name}."
      
      # Update the message with the real response
      message.update(content: ai_response)
      
      # Broadcast the updated message to all clients
      Turbo::StreamsChannel.broadcast_replace_to(
        "conversation_#{conversation.id}",
        target: dom_id(message),
        partial: "ai/messages/message",
        locals: { message: message }
      )
    rescue => e
      Rails.logger.error("Error generating AI response: #{e.message}")
      message.update(content: "Sorry, I encountered an error while processing your request.")
      
      Turbo::StreamsChannel.broadcast_replace_to(
        "conversation_#{conversation.id}",
        target: dom_id(message),
        partial: "ai/messages/message",
        locals: { message: message }
      )
      puts e.backtrace.join("\n")
    end
  end

  private

  def dom_id(message)
    ActionView::RecordIdentifier.dom_id(message)
  end
end
