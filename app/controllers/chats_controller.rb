class ChatsController < ApplicationController
  before_action :set_chat, only: [:show, :destroy]

  def index
    @chats = Chat.order(created_at: :desc)
  end

  def new
    @chat = Chat.new
    @selected_model = params[:model]
  end

  def create
    return unless prompt.present?

    @chat = Chat.create!(model: model)
    ChatResponseJob.perform_later(@chat.id, prompt)

    redirect_to @chat, notice: 'Chat was successfully created.'
  end

  def show
    @message = @chat.messages.build
  end

  def destroy
    if @chat.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = 'Chat was successfully deleted.'
          # renders destroy.turbo_stream.erb
        end
        format.html { redirect_to chats_path, notice: 'Chat was successfully deleted.' }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = 'Chat could not be deleted.'
          render :destroy_failure, status: :unprocessable_entity
        end
        format.html { redirect_to @chat, alert: 'Chat could not be deleted.' }
      end
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  def model
    params[:chat][:model].presence
  end

  def prompt
    params[:chat][:prompt]
  end
end