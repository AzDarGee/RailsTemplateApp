class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :status, default: 'active'
      t.string :processor
      t.string :processor_id
      t.string :processor_plan
      t.datetime :trial_ends_at
      t.datetime :ends_at
      
      t.timestamps
    end
    
    add_index :subscriptions, :processor_id, unique: true
  end
end 