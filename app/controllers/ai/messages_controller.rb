class Ai::MessagesController < ApplicationController
  before_action :set_agent
  before_action :set_conversation
  before_action :set_message, only: %i[ show update destroy ]

  # GET /ai/messages or /ai/messages.json
  def index
    @messages = @conversation.messages.order(created_at: :asc)
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /ai/messages/1 or /ai/messages/1.json
  def show
  end

  # GET /ai/messages/new
  def new
    @message = Ai::Message.new
  end

  # POST /ai/messages or /ai/messages.json
  def create
    @message = @conversation.messages.build(message_params)
    @message.role = "User"

    respond_to do |format|
      if @message.save
        # Broadcast the user message to the conversation channel
        Turbo::StreamsChannel.broadcast_append_to(
          "conversation_#{@conversation.id}_messages",
          target: "messages-container",
          partial: "ai/messages/message",
          locals: { message: @message, agent: @agent }
        )

        # Generate AI response asynchronously
        generate_ai_response(@message)
        
        # Render the Turbo Stream template or redirect for HTML requests
        format.turbo_stream
        format.html { redirect_to ai_agent_conversation_path(@agent, @conversation) }
      else
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace(
            "message-form",
            partial: "ai/messages/form", 
            locals: { agent: @agent, conversation: @conversation, message: @message }
          )
        }
        format.html { redirect_to ai_agent_conversation_path(@agent, @conversation), alert: "Failed to send message" }
      end
    end
  end

  # PATCH/PUT /ai/messages/1 or /ai/messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ai/messages/1 or /ai/messages/1.json
  def destroy
    @message.destroy!

    respond_to do |format|
      format.html { redirect_to ai_messages_path, status: :see_other, notice: "Message was successfully destroyed." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Ai::Message.find(params[:id])
    end

    def set_conversation
      @conversation = current_user.conversations.find(params[:conversation_id])
    end

    def set_agent
      @agent = current_user.agents.find(params[:agent_id])
    end

    # Only allow a list of trusted parameters through.
    def message_params
      params.permit(:content, :tool_calls, :tool_call_id)
    end

    def generate_ai_response(message)
      # Create a placeholder message immediately
      @ai_message = @conversation.messages.create(
        content: "Thinking...",
        role: "AI Agent"
      )
      
      # Broadcast the placeholder message
      Turbo::StreamsChannel.broadcast_append_to(
        "conversation_#{@conversation.id}_messages",
        target: "messages-container",
        partial: "ai/messages/message",
        locals: { message: @ai_message, agent: @agent }
      )

      # Process the AI response in a background job
      AiResponseJob.perform_later(@ai_message, @conversation, @agent)
    end

    def dom_id(message)
      ActionView::RecordIdentifier.dom_id(message)
    end
end
