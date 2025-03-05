class Avo::Resources::User < Avo::BaseResource
  self.title = -> {
    [ record.id, record.email ].compact.join(" - ")
  }
  
  # self.includes = []
  # self.attachments = []
  self.search = {
    query: -> { 
      query.ransack(
        id_eq: params[:q], 
        name_cont: params[:q], 
        email_cont: params[:q],
        username_cont: params[:q],
        m: "or"
      ).result(distinct: false) 
    }
  }
  
  def fields
    field :id, as: :id
    field :admin, as: :boolean
    field :email, as: :text
    field :sign_in_count, as: :number
    field :current_sign_in_at, as: :date_time, hide_on: :index
    field :last_sign_in_at, as: :date_time, hide_on: :index
    field :current_sign_in_ip, as: :text, hide_on: :index
    field :last_sign_in_ip, as: :text, hide_on: :index
    field :confirmation_token, as: :text, hide_on: :index
    field :confirmed_at, as: :date_time, hide_on: :index
    field :confirmation_sent_at, as: :date_time, hide_on: :index
    field :unconfirmed_email, as: :text, hide_on: :index
    field :failed_attempts, as: :number, hide_on: :index
    field :unlock_token, as: :text, hide_on: :index
    field :locked_at, as: :date_time, hide_on: :index
    field :username, as: :text
    field :provider, as: :text
    field :uid, as: :text, hide_on: :index
    field :name, as: :text
    field :image, as: :text
    field :billing_name, as: :text, hide_on: :index
    field :billing_email, as: :text, hide_on: :index
    field :billing_address, as: :text, hide_on: :index
    field :billing_city, as: :text, hide_on: :index
    field :billing_state, as: :text, hide_on: :index
    field :billing_zip, as: :text, hide_on: :index
    field :billing_country, as: :text, hide_on: :index
    field :avatar, as: :file
    field :agents, as: :has_many
    field :conversations, as: :has_many
    field :bio, as: :trix
  end
end
