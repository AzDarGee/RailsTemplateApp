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
  end

  def show
    @agent = Ai::Agent.find(params[:id])

    @old_tasks = Ai::AgentTask.where(agent: @agent, parent_task: nil)

    @task = Ai::AgentTask.create!(
      agent: @agent,
      user: current_user,
      parent_task: nil
    )
  end

  def create
    @agent = Ai::Agent.new(agent_params)
    
    respond_to do |format|
      if @agent.save
        format.html { redirect_to ai_agent_path(@agent), notice: "Agent created successfully" }
      else
        format.html { render :new, status: :unprocessable_entity, alert: "Failed to create agent" }
      end
    end
  end

  def create_message
    task = Ai::AgentTask.find(params[:task_id])

    user_message = task.messages.create!(
      role: "user",
      content: params[:message]
    )

    task.agent.run!(task)

    render turbo_stream: turbo_stream.replace(
      "message-form",
      partial: "ai/agents/form",
      locals: { task: task }
    )
  end

  private

  def set_agent
    @agent = Ai::Agent.find(params[:id])
  end

  def agent_params
    params.require(:ai_agent).permit(:name, :description, :instructions, :tools)
  end
end
