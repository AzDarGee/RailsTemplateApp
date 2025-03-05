class Avo::Resources::Message < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = Ai::Message
  self.search = {
    query: -> { 
      query.ransack(
        id_eq: params[:q],
        role_cont: params[:q],
        content_cont: params[:q],
        m: "or"
      ).result(distinct: false) }
  }
  
  def fields
    field :id, as: :id
    field :role, as: :text
    field :content, as: :textarea
    field :tool_calls, as: :text
    field :tool_call_id, as: :text
    field :conversation_id, as: :number
    field :conversation, as: :belongs_to
  end
end
