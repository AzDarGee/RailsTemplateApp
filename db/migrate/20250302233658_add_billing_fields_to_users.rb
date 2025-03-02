class AddBillingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :billing_name, :string
    add_column :users, :billing_email, :string
    add_column :users, :billing_address, :string
    add_column :users, :billing_city, :string
    add_column :users, :billing_state, :string
    add_column :users, :billing_zip, :string
    add_column :users, :billing_country, :string
  end
end
