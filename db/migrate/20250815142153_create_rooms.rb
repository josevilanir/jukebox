class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :rooms, :slug, unique: true
  end
end
