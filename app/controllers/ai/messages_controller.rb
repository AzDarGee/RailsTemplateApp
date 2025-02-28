class Ai::MessagesController < ApplicationController
  before_action :set_ai_conversation
  before_action :set_ai_message, only: %i[ show edit update destroy ]

  # GET /ai/messages or /ai/messages.json
  def index
    @ai_messages = Ai::Message.all
  end

  # GET /ai/messages/1 or /ai/messages/1.json
  def show
  end

  # GET /ai/messages/new
  def new
    @ai_message = Ai::Message.new
  end

  # GET /ai/messages/1/edit
  def edit
  end

  # POST /ai/messages or /ai/messages.json
  def create
    @ai_message = Ai::Message.new(ai_message_params)

    respond_to do |format|
      if @ai_message.save
        format.html { redirect_to @ai_message, notice: "Message was successfully created." }
        format.json { render :show, status: :created, location: @ai_message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ai_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ai/messages/1 or /ai/messages/1.json
  def update
    respond_to do |format|
      if @ai_message.update(ai_message_params)
        format.html { redirect_to @ai_message, notice: "Message was successfully updated." }
        format.json { render :show, status: :ok, location: @ai_message }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ai_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ai/messages/1 or /ai/messages/1.json
  def destroy
    @ai_message.destroy!

    respond_to do |format|
      format.html { redirect_to ai_messages_path, status: :see_other, notice: "Message was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ai_message
      @ai_message = Ai::Message.find(params.expect(:id))
    end

    def set_ai_conversation
      @ai_conversation = current_user.conversations.find(params[:conversation_id])
    end

    # Only allow a list of trusted parameters through.
    def ai_message_params
      params.expect(ai_message: [ :role, :content, :tool_calls, :tool_call_id, :conversation_id ])
    end

    def generate_ai_response
      # Create a placeholder message immediately
      @ai_message = @ai_conversation.messages.create(
        content: "Thinking...",
        sender: "agent"
      )
  
      # In a real app, you'd use a background job here
      # For demo purposes, we'll simulate a delay and update the message
      AiResponseJob.perform_later(@ai_message.id, @ai_conversation.id)
    end
end
