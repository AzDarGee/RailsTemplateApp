class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.string  :key,           null: false
      t.string  :name,          null: false
      t.string  :env_price_key, null: false
      t.string  :interval,      null: false, default: "month"
      t.integer :price_cents,   null: false, default: 0
      t.boolean :active,        null: false, default: true
      t.integer :position,      null: false, default: 0

      t.timestamps
    end

    add_index :plans, :key, unique: true
    add_index :plans, :active
    add_index :plans, :position
  end
end
