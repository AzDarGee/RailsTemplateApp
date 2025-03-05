class Avo::Resources::Agent < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = Ai::Agent
  self.search = {
    query: -> { 
      query.ransack(
        id_eq: params[:q], 
        name_cont: params[:q],
        description_cont: params[:q],
        instructions_cont: params[:q],
        tools_cont: params[:q],
        user_name_cont: params[:q],
        user_email_cont: params[:q],
        user_username_cont: params[:q],
        user_id_eq: params[:q],
        m: "or"
      ).result(distinct: false) 
    }
  }
  
  def fields
    field :id, as: :id
    field :name, as: :text
    field :description, as: :textarea
    field :instructions, as: :textarea
    field :tools, as: :text
    field :user_id, as: :number
    field :tasks, as: :has_many
    field :conversations, as: :has_many
    field :user, as: :belongs_to
  end
end
