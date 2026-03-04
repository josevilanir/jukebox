class AddNameSetToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name_set, :boolean, default: false, null: false
  end
end
