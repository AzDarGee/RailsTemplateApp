class CreatePlansTable < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.text :description, null: false
      t.text :features, null: false  # For PostgreSQL, you can use t.string :features, array: true
      t.boolean :popular, default: false
      t.string :billing_frequency, default: 'monthly'
      
      t.timestamps
    end
    
    add_index :plans, :name, unique: true
  end
end
