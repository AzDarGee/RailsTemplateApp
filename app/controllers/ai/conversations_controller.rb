class Ai::ConversationsController < ApplicationController
  before_action :set_ai_conversation, only: %i[ show destroy ]

  # GET /ai/conversations or /ai/conversations.json
  def index
    @ai_conversations = Ai::Conversation.all
  end

  # GET /ai/conversations/1 or /ai/conversations/1.json
  def show
  end

  # GET /ai/conversations/new
  def new
    @ai_conversation = Ai::Conversation.new
  end

  # POST /ai/conversations or /ai/conversations.json
  def create
    @ai_conversation = Ai::Conversation.new(ai_conversation_params)

    respond_to do |format|
      if @ai_conversation.save
        format.html { redirect_to @ai_conversation, notice: "Conversation was successfully created." }
        format.json { render :show, status: :created, location: @ai_conversation }
      else
        format.html { render :new, status: :unprocessable_entity }
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
      @ai_conversation = Ai::Conversation.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def ai_conversation_params
      params.expect(ai_conversation: [ :title, :category, :user_id ])
    end
end
