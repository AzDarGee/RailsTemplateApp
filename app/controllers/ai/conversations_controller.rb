class Ai::ConversationsController < ApplicationController
  before_action :set_ai_agent
  before_action :set_ai_conversation, only: [ :show ]

  # GET /ai/conversations or /ai/conversations.json
  def index
    @ai_conversations = @agent.conversations.where(user: current_user).order(created_at: :desc)
  end

  # GET /ai/conversations/1 or /ai/conversations/1.json
  def show
    @messages = @ai_conversation.messages.order(created_at: :asc)
    @message = Ai::Message.new
  end

  # GET /ai/conversations/new
  def new
    @ai_conversation = Ai::Conversation.new
  end

  # POST /ai/conversations or /ai/conversations.json
  def create
    # @ai_conversation = Ai::Conversation.new(ai_conversation_params)
    @ai_conversation = @ai_agent.conversations.build(user: current_user, title: "New Conversation #{Time.now.strftime('%Y-%m-%d %H:%M')}")

    respond_to do |format|
      if @ai_conversation.save
        format.html { redirect_to ai_agent_conversation_path(@ai_agent, @ai_conversation) }
        format.turbo_stream
      else
        format.html { redirect_to ai_agent_path(@ai_agent), alert: "Failed to create conversation" }
        format.json { render json: @ai_conversation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ai/conversations/1 or /ai/conversations/1.json
  def destroy
    @ai_conversation.destroy!

    respond_to do |format|
      format.html { redirect_to ai_conversations_path, status: :see_other, notice: "Conversation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ai_conversation
      # @ai_conversation = Ai::Conversation.find(params.expect(:id))
      @ai_conversation = @ai_agent.conversations.where(user: current_user).find(params[:id])
    end

    def set_ai_agent
      # @ai_agent = Ai::Agent.find(params.expect(:agent_id))
      @ai_agent = current_user.ai_agents.find(params[:agent_id])
    end

    # Only allow a list of trusted parameters through.
    def ai_conversation_params
      params.expect(ai_conversation: [ :title, :category, :user_id, :agent_id ])
    end
end
