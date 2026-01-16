class Avo::Resources::Chat < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :model_id, as: :number
    field :messages, as: :has_many
    field :model, as: :belongs_to
  end
end
