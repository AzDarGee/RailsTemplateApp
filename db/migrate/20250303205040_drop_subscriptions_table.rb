class DropSubscriptionsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :subscriptions
  end

  def down
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :status
      t.string :processor
      t.string :processor_id
      t.string :processor_plan
      t.datetime :trial_ends_at
      t.datetime :ends_at
      t.integer :quantity, default: 1, null: false
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end

    add_index :subscriptions, :data, using: :gin
  end
end
