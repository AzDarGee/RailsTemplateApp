class AgentsController < ApplicationController
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
    # @agent = Ai::Agent.where(
    #   name: "general_assistant",
    #   description: "A general assistant that can help with a variety of tasks",
    #   instructions: "You're a helpful AI assistant that can help with a variety of tasks",
    #   tools: []
    # ).first_or_create!

    @task = Ai::AgentTask.create!(
      agent: @agent,
      user: current_user,
      parent_task: nil
    )
  end

  def create
    task = Ai::AgentTask.find(params[:task_id])

    user_message = task.messages.create!(
      role: "user",
      content: params[:message]
    )

    task.agent.run!(task)

    render turbo_stream: turbo_stream.replace(
      "message-form",
      partial: "agents/form",
      locals: { task: task }
    )
  end

  private

  def set_agent
    @agent = Ai::Agent.find(params[:id])
  end
end
