class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(ai_message, conversation, agent)
    begin
      # Get conversation history
      conversation_messages = conversation.messages.order(created_at: :asc)

      assistant = Langchain::Assistant.new(
        llm: open_ai_llm,
        instructions: agent.instructions,
        tools: agent.tools.map { |tool| available_tools[tool.to_sym] }.compact
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
      ai_message.update(content: "Sorry, I encountered an error while processing your request. \n \n #{e.message}")

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

  def open_ai_llm
    @open_ai ||= Langchain::LLM::OpenAI.new(
        api_key: Rails.application.credentials.dig(:ai, :open_ai, :api_key),
        default_options: { temperature: 0.7 }
    )
  end

  def gemini_llm
    @gemini ||= Langchain::LLM::GoogleGemini.new(
        api_key: Rails.application.credentials.dig(:ai, :gemini, :api_key),
        default_options: { temperature: 0.7, chat_model: "gemini-2.5-pro" }
    )
  end

  def open_router_llm
    @open_router ||= Langchain::LLM::OpenRouter.new(
        api_key: Rails.application.credentials.dig(:ai, :open_router, :api_key),
        model: "gpt-4o",
        default_options: { temperature: 0.7 }
    )
  end

  def available_tools
    {
      web_search: Langchain::Tool::Tavily.new(api_key: Rails.application.credentials.dig(:ai, :tavily, :api_key))
      # calculator: Langchain::Tool::Calculator.new,
      # wikipedia: Langchain::Tool::Wikipedia.new,
      # file_search: Langchain::Tool::FileSearch.new(base_path: Rails.root.join("storage", "ai_files")),
      # resumable_file_search: Langchain::Tool::ResumableFileSearch.new(base_path: Rails.root.join("storage", "ai_files")),
      # url_content_reader: Langchain::Tool::UrlContentReader.new,
      # code_executor: Langchain::Tool::CodeExecutor.new(runtime: :ruby),
      # news: Langchain::Tool::NewsRetriever.new(api_key: Rails.application.credentials.dig(:ai, :news_api, :api_key)),
      # weather: Langchain::Tool::Weather.new(api_key: Rails.application.credentials.dig(:ai, :weather_api, :api_key))
    }
  end
end
