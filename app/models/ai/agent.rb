module Ai
    class Agent
        def run!(messages)
            assistant = Langchain::Assistant.new(
                llm: llm,
                instructions: "You're a helpful AI assistant",
                tools: []
            )

            messages.each do |message|
                assistant.add_message(
                    role: message[:role],
                    content: message[:content]
                )
            end

            
            assistant.run(auto_tool_execution: true)
            last_message = assistant.messages.last

            {
                role: last_message.role,
                content: last_message.content
            }
        end

        private

        def llm
            @llm ||= Langchain::LLM::OpenAI.new(api_key: Rails.application.credentials.dig(:ai, :open_ai, :api_key))
        end
    end
end