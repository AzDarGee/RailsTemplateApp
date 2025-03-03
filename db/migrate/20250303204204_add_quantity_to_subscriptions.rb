class AddQuantityToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :quantity, :integer, default: 1, null: false
  end
end
