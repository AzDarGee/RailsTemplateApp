class AddDataToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :data, :jsonb, default: {}, null: false
    add_index :subscriptions, :data, using: :gin
  end
end
