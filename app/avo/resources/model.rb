class Avo::Resources::Model < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :model_id, as: :text
    field :name, as: :text
    field :provider, as: :text
    field :family, as: :text
    field :model_created_at, as: :date_time
    field :context_window, as: :number
    field :max_output_tokens, as: :number
    field :knowledge_cutoff, as: :date
    field :modalities, as: :code
    field :capabilities, as: :code
    field :pricing, as: :code
    field :metadata, as: :code
    field :chats, as: :has_many
  end
end
