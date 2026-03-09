class CreateVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :votes do |t|
      t.references :queue_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :value, null: false, default: 1
      t.timestamps
    end
    add_index :votes, [ :queue_item_id, :user_id ], unique: true
  end
end
