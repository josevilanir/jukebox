class AddSystemFieldsToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :system, :boolean, default: false
    add_column :messages, :system_type, :string
  end
end
