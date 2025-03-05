class Avo::Resources::User < Avo::BaseResource
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
    field :email, as: :text
    field :sign_in_count, as: :number
    field :current_sign_in_at, as: :date_time
    field :last_sign_in_at, as: :date_time
    field :current_sign_in_ip, as: :text
    field :last_sign_in_ip, as: :text
    field :confirmation_token, as: :text
    field :confirmed_at, as: :date_time
    field :confirmation_sent_at, as: :date_time
    field :unconfirmed_email, as: :text
    field :failed_attempts, as: :number
    field :unlock_token, as: :text
    field :locked_at, as: :date_time
    field :username, as: :text
    field :provider, as: :text
    field :uid, as: :text
    field :name, as: :text
    field :image, as: :text
    field :admin, as: :boolean
    field :billing_name, as: :text
    field :billing_email, as: :text
    field :billing_address, as: :text
    field :billing_city, as: :text
    field :billing_state, as: :text
    field :billing_zip, as: :text
    field :billing_country, as: :text
    field :avatar, as: :file
    field :agents, as: :has_many
    field :conversations, as: :has_many
    field :bio, as: :trix
  end
end
