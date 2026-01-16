class Avo::Resources::Message < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  self.search = {
    query: -> {
      query.ransack(
        id_eq: params[:q],
        content_cont: params[:q],
        role_cont: params[:q],
        model_cont: params[:q],
        m: "or"
      ).result(distinct: false)
    }
  }

  def fields
    field :id, as: :id
    field :chat_id, as: :number
    field :content, as: :textarea
    field :input_tokens, as: :number
    field :model_id, as: :number
    field :output_tokens, as: :number
    field :role, as: :text
    field :tool_call_id, as: :number
    field :attachments, as: :files
    field :chat, as: :belongs_to
    field :tool_calls, as: :has_many
    field :parent_tool_call, as: :belongs_to
    field :tool_results, as: :has_many, through: :tool_calls
    field :model, as: :belongs_to
  end
end
