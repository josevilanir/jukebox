class AddDjModeToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :dj_mode, :boolean, default: false, null: false
  end
end
