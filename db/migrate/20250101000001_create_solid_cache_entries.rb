class CreateSolidCacheEntries < ActiveRecord::Migration[8.0]
  def up
    # If table exists but with wrong schema (missing byte_size column), drop and recreate
    if table_exists?(:solid_cache_entries)
      unless column_exists?(:solid_cache_entries, :byte_size)
        drop_table :solid_cache_entries
      else
        return # Table exists with correct schema, nothing to do
      end
    end

    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536870912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false

      t.index :byte_size, name: "index_solid_cache_entries_on_byte_size"
      t.index [ :key_hash, :byte_size ], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index :key_hash, name: "index_solid_cache_entries_on_key_hash", unique: true
    end
  end

  def down
    drop_table :solid_cache_entries, if_exists: true
  end
end
