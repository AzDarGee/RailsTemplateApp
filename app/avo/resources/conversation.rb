class Avo::Resources::Conversation < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = Ai::Conversation
  self.search = {
    query: -> { 
      query.ransack(
        id_eq: params[:q], 
        title_cont: params[:q],
        category_cont: params[:q],
        user_name_cont: params[:q],
        user_email_cont: params[:q],
        user_username_cont: params[:q],
        user_id_eq: params[:q],
        agent_name_cont: params[:q],
        agent_description_cont: params[:q],
        agent_id_eq: params[:q],
        m: "or"
      ).result(distinct: false) 
    }
  }
  
  def fields
    field :id, as: :id
    field :title, as: :text
    field :category, as: :text
    field :user_id, as: :number
    field :agent_id, as: :number
    field :user, as: :belongs_to
    field :agent, as: :belongs_to
    field :messages, as: :has_many
  end
end
