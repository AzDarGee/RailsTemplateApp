class Ai::Agent < ApplicationRecord
    has_many :tasks, class_name: "Ai::AgentTask", dependent: :destroy
    has_many :conversations, class_name: "Ai::Conversation", dependent: :destroy
    belongs_to :user

    before_validation do
        self.tools = [] if tools.blank?
    end

    # normalizes :tools, with: -> (value) {
    #     value.is_a?(String) ? JSON.parse(value) : value
    # }

    def run!(task)
        begin
            assistant = Langchain::Assistant.new(
                llm: llm,
                instructions: instructions,
                tools: tools
            )
      
            assistant.run(auto_tool_execution: true)
      
            last_message = assistant.messages.last
        
            {
                role: last_message.role,
                content: last_message.content
            }
        rescue => e
            Rails.logger.error("Error running agent: #{e.message}")
            raise e
        end
    end

    private

    def llm
        @llm ||= Langchain::LLM::OpenAI.new(
            api_key: Rails.application.credentials.dig(:ai, :open_ai, :api_key)
        )
    end

    def available_tools
        {
            web_search: Langchain::Tool::Tavily.new(api_key: Rails.application.credentials.dig(:ai, :tavily, :api_key))
        }
    end
end
