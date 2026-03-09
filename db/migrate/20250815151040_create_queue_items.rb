class CreateQueueItems < ActiveRecord::Migration[7.1]
  def change
    create_table :queue_items do |t|
      t.references :room, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.references :added_by, null: false, foreign_key: { to_table: :users }
      t.integer :position, null: false, default: 0
      t.datetime :played_at
      t.timestamps
    end

    add_index :queue_items, [ :room_id, :position ]
  end
end
