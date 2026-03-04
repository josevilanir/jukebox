class CreateSkipVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :skip_votes do |t|
      t.references :queue_item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :skip_votes, [:queue_item_id, :user_id], unique: true
  end
end
