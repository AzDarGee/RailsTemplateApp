class Ai::AgentsController < ApplicationController
  before_action :set_agent, only: [:edit, :update, :destroy, :show]
  
  def index
    @agents = Ai::Agent.all
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
    @agent = Ai::Agent.find(params[:id])

    @old_tasks = Ai::AgentTask.where(agent: @agent, parent_task: nil)

    if @old_tasks.any?
      @old_tasks.each do |task|
        if task.messages.empty?
          task.destroy
        end
      end
    end

    @task = Ai::AgentTask.create(
      agent: @agent,
      user: current_user,
      parent_task: nil
    )
  end

  def create
    @agent = Ai::Agent.new(agent_params)
    @agent.user = current_user
    
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
    @agent = Ai::Agent.find(params[:id])
  end

  def agent_params
    params.require(:ai_agent).permit(:name, :description, :instructions, :tools)
  end
end
