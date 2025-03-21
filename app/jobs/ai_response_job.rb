class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(ai_message, conversation, agent)
    begin
      # Get conversation history
      conversation_messages = conversation.messages.order(created_at: :asc)
    
      assistant = Langchain::Assistant.new(
        llm: llm,
        instructions: agent.instructions,
        tools: agent.tools
      )
      
      # Add conversation history to the assistant
      conversation_messages.each do |msg|
        assistant.add_message(
          content: msg.content
        )
      end
      
      assistant.run(auto_tool_execution: true)
      
      # Get the last message from the assistant
      last_message = assistant.messages.last

      # Update the placeholder message with the real response
      ai_message.update(
        content: last_message.content,
        role: "AI Agent",
        tool_calls: last_message.tool_calls,
        tool_call_id: last_message.tool_call_id
      )

      # Broadcast the updated message to all clients
      Turbo::StreamsChannel.broadcast_replace_to(
        "conversation_#{conversation.id}_messages",
        target: dom_id(ai_message),
        partial: "ai/messages/message",
        locals: { message: ai_message, agent: agent }
      )

    rescue => e
      Rails.logger.error("Error generating AI response: #{e.message}")
      ai_message.update(content: "Sorry, I encountered an error while processing your request.")
      
      Turbo::StreamsChannel.broadcast_replace_to(
        "conversation_#{conversation.id}_messages",
        target: dom_id(ai_message),
        partial: "ai/messages/message",
        locals: { message: ai_message, agent: agent }
      )
      puts e.backtrace.join("\n")
    end
  end

  private

  def dom_id(message)
    ActionView::RecordIdentifier.dom_id(message)
  end

  def llm
    @llm ||= Langchain::LLM::OpenAI.new(
        api_key: Rails.application.credentials.dig(:ai, :open_ai, :api_key)
    )
  end
end
