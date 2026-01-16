class Avo::Resources::ToolCall < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :arguments, as: :code
    field :message_id, as: :number
    field :name, as: :text
    field :tool_call_id, as: :text
    field :message, as: :belongs_to
    field :result, as: :has_one
  end
end
