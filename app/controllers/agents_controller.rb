class AgentsController < ApplicationController
  def show
  end

  def create
    message = params[:message]
    user_message = { role: "user", content: message }

    response = Ai::Agent.new.run!([user_message])

    render turbo_stream: [
      turbo_stream.append(
        "messages",
        html: MessageComponent.new(message: user_message).render_in(view_context)
      ),
      turbo_stream.append(
        "messages",
        html: MessageComponent.new(message: response).render_in(view_context)
      )
    ]
  end
end
