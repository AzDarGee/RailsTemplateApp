class Ai::MessagesController < ApplicationController
  before_action :set_conversation
  before_action :set_message, only: %i[ show edit update destroy ]

  # GET /ai/messages or /ai/messages.json
  def index
    @messages = Ai::Message.all
  end

  # GET /ai/messages/1 or /ai/messages/1.json
  def show
  end

  # GET /ai/messages/new
  def new
    @message = Ai::Message.new
  end

  # GET /ai/messages/1/edit
  def edit
  end

  # POST /ai/messages or /ai/messages.json
  def create
    @message = @conversation.messages.build(message_params)
    @message.role = "user"

    respond_to do |format|
      if @message.save
        # Trigger AI response after user message is saved
        generate_ai_response
        
        format.turbo_stream
        format.html { redirect_to agent_conversation_path(@conversation.agent, @conversation) }
      
        format.json { render :show, status: :created, location: @message }
      else
        format.html { redirect_to agent_conversation_path(@conversation.agent, @conversation), alert: "Failed to send message" }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ai/messages/1 or /ai/messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to @message, notice: "Message was successfully updated." }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ai/messages/1 or /ai/messages/1.json
  def destroy
    @message.destroy!

    respond_to do |format|
      format.html { redirect_to ai_messages_path, status: :see_other, notice: "Message was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = Ai::Message.find(params.expect(:id))
    end

    def set_conversation
      @conversation = current_user.conversations.find(params[:conversation_id])
    end

    # Only allow a list of trusted parameters through.
    def message_params
      params.expect(message: [ :role, :content, :tool_calls, :tool_call_id, :conversation_id ])
    end

    def generate_ai_response
      # Create a placeholder message immediately
      @ai_message = @conversation.messages.create!(
        content: "Thinking...",
        role: "agent"
      )
  
      # In a real app, you'd use a background job here
      # For demo purposes, we'll simulate a delay and update the message
      AiResponseJob.perform_later(@ai_message.id, @conversation.id)
    end
end
