class CreateRoomMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :room_memberships do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :room_memberships, [:room_id, :user_id], unique: true
  end
end
