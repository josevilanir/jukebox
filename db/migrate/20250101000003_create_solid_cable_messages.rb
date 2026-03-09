class CreateSolidCableMessages < ActiveRecord::Migration[8.0]
  def up
    unless table_exists?(:solid_cable_messages)
      create_table :solid_cable_messages do |t|
        t.binary :channel, limit: 1024, null: false
        t.binary :payload, limit: 536870912, null: false
        t.datetime :created_at, null: false
        t.integer :channel_hash, limit: 8, null: false
      end
    end

    unless index_exists?(:solid_cable_messages, :channel, name: "index_solid_cable_messages_on_channel")
      add_index :solid_cable_messages, :channel, name: "index_solid_cable_messages_on_channel"
    end
    unless index_exists?(:solid_cable_messages, :channel_hash, name: "index_solid_cable_messages_on_channel_hash")
      add_index :solid_cable_messages, :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
    end
    unless index_exists?(:solid_cable_messages, :created_at, name: "index_solid_cable_messages_on_created_at")
      add_index :solid_cable_messages, :created_at, name: "index_solid_cable_messages_on_created_at"
    end
  end

  def down
    drop_table :solid_cable_messages, if_exists: true
  end
end
