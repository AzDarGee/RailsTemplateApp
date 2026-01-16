class Avo::Resources::Model < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  self.search = {
    query: -> {
      query.ransack(
        id_eq: params[:q],
        name_cont: params[:q],
        family_cont: params[:q],
        provider_cont: params[:q],
        m: "or"
      ).result(distinct: false)
    }
  }

  def fields
    field :id, as: :id
    field :capabilities, as: :code
    field :context_window, as: :number
    field :family, as: :text
    field :knowledge_cutoff, as: :date
    field :max_output_tokens, as: :number
    field :metadata, as: :code
    field :modalities, as: :code
    field :model_created_at, as: :date_time
    field :model_id, as: :text
    field :name, as: :text
    field :pricing, as: :code
    field :provider, as: :text
    field :chats, as: :has_many
  end
end
