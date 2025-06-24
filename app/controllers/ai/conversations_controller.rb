class Ai::ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agent
  before_action :set_conversation, only: [ :show, :destroy ]

  # GET /ai/conversations or /ai/conversations.json
  def index
    @conversations = @agent.conversations.where(user: current_user).order(created_at: :desc)

    if params[:query].present?
      @conversations = @conversations.where("title ILIKE ?", "%#{params[:query]}%")
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("conversations_list",
          partial: "ai/conversations/conversation_list",
          locals: { conversations: @conversations, agent: @agent })
      end
    end
  end

  # GET /ai/conversations/1 or /ai/conversations/1.json
  def show
    @messages = @conversation.messages.order(created_at: :asc)
    @message = Ai::Message.new
  end

  # GET /ai/conversations/new
  def new
    @conversation = Ai::Conversation.new
  end

  # POST /ai/conversations or /ai/conversations.json
  def create
    @conversation = @agent.conversations.build(
      user: current_user,
      title: "New Conversation #{Time.now.strftime('%Y-%m-%d %H:%M')}",
      category: "AI Conversation"
    )

    respond_to do |format|
      if @conversation.save
        # Broadcast the new conversation to the conversations list
        Turbo::StreamsChannel.broadcast_prepend_to(
          "user_#{current_user.id}_agent_#{@agent.id}_conversations",
          target: "conversations-list",
          partial: "ai/conversations/conversation_row",
          locals: { conversation: @conversation, agent: @agent }
        )

        # Also broadcast to the conversation page if that's where the user is
        Turbo::StreamsChannel.broadcast_prepend_to(
          "agent_#{@agent.id}_conversations",
          target: "conversations_list",
          partial: "ai/conversations/conversation_item",
          locals: { conversation: @conversation, agent: @agent, current_conversation: nil }
        )

        # Check if this was the first conversation (count = 1 including the new one)
        empty_state = (@agent.conversations.where(user: current_user).count == 0)

        if empty_state
          # Remove the empty state placeholder
          Turbo::StreamsChannel.broadcast_remove_to(
            "user_#{current_user.id}_agent_#{@agent.id}_conversations",
            target: "empty-conversations-placeholder"
          )

          # Show the conversations table
          Turbo::StreamsChannel.broadcast_replace_to(
            "user_#{current_user.id}_agent_#{@agent.id}_conversations",
            target: "conversations-table-container",
            html: '<div id="conversations-table-container">
                    <div class="table-responsive">
                      <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                          <tr>
                            <th scope="col" class="ps-4">Title</th>
                            <th scope="col">Last Message</th>
                            <th scope="col">Created</th>
                            <th scope="col">Updated</th>
                            <th scope="col" class="text-end pe-4">Actions</th>
                          </tr>
                        </thead>
                        <tbody id="conversations-list">
                          <!-- Conversations will be added here -->
                        </tbody>
                      </table>
                    </div>
                  </div>'
          )
        end

        format.turbo_stream
        format.html { redirect_to ai_agent_conversation_path(@agent, @conversation), notice: "Conversation started!" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash",
            locals: { type: "danger", message: "Failed to create conversation" })
        end
        format.html { redirect_to ai_agent_path(@agent), alert: "Failed to create conversation" }
      end
    end
  end

  # DELETE /ai/conversations/1 or /ai/conversations/1.json
  def destroy
    @conversation.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to ai_agent_path(@agent), notice: "Conversation was deleted." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conversation
      # @ai_conversation = Ai::Conversation.find(params.expect(:id))
      @conversation = @agent.conversations.where(user: current_user).find(params[:id])
    end

    def set_agent
      # @ai_agent = Ai::Agent.find(params.expect(:agent_id))
      @agent = current_user.agents.find(params[:agent_id])
    end

    # Only allow a list of trusted parameters through.
    def conversation_params
      params.expect(conversation: [ :title, :category, :user_id, :agent_id ])
    end
end
