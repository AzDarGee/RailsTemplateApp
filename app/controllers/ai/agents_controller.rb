class Ai::AgentsController < ApplicationController
  before_action :set_agent, only: [:edit, :update, :destroy, :show]
  
  def index
    @agents = current_user.agents.order(created_at: :desc)
  end

  def new
    @agent = Ai::Agent.new
  end

  def edit
  end

  def update
  end

  def destroy
    @agent.destroy
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.remove("agent_#{@agent.id}"), 
        notice: "Agent deleted successfully" 
      }
    end
  end

  def show
  end

  def create
    @agent = current_user.agents.new(agent_params)
    
    respond_to do |format|
      if @agent.save
        format.html { redirect_to ai_agent_path(@agent), notice: "Agent created successfully" }
      else
        format.html { render :new, status: :unprocessable_entity, alert: "Failed to create agent" }
      end
    end
  end

  private

  def set_agent
    @agent = current_user.agents.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name, :description, :instructions, :tools, :avatar)
  end
end
