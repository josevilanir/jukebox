class CreateSolidCacheEntries < ActiveRecord::Migration[8.0]
  def up
    unless table_exists?(:solid_cache_entries)
      create_table :solid_cache_entries do |t|
        t.binary :key, limit: 1024, null: false
        t.binary :value, limit: 536870912, null: false
        t.datetime :created_at, null: false
        t.integer :key_hash, limit: 8, null: false
        t.integer :byte_size, limit: 4, null: false
      end
    end

    unless index_exists?(:solid_cache_entries, :byte_size, name: "index_solid_cache_entries_on_byte_size")
      add_index :solid_cache_entries, :byte_size, name: "index_solid_cache_entries_on_byte_size"
    end
    unless index_exists?(:solid_cache_entries, [ :key_hash, :byte_size ], name: "index_solid_cache_entries_on_key_hash_and_byte_size")
      add_index :solid_cache_entries, [ :key_hash, :byte_size ], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    end
    unless index_exists?(:solid_cache_entries, :key_hash, name: "index_solid_cache_entries_on_key_hash")
      add_index :solid_cache_entries, :key_hash, name: "index_solid_cache_entries_on_key_hash", unique: true
    end
  end

  def down
    drop_table :solid_cache_entries, if_exists: true
  end
end
