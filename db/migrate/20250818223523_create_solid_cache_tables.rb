class CreateSolidCacheTables < ActiveRecord::Migration[7.2]
  def change
    # Create solid_cache_entries table for SolidCache
    # This table stores cached data with binary key-value pairs for high performance
    create_table :solid_cache_entries, force: :cascade do |t|
      # Binary cache key (limited to 1024 bytes for performance)
      t.binary :key, limit: 1024, null: false
      
      # Binary cache value (limited to 512MB for large cached objects)
      t.binary :value, limit: 536870912, null: false
      
      # Timestamp when the cache entry was created
      t.datetime :created_at, null: false
      
      # Hash of the key for efficient indexing and lookups
      t.integer :key_hash, limit: 8, null: false
      
      # Size of the cached value in bytes for monitoring and cleanup
      t.integer :byte_size, limit: 4, null: false
    end

    # Add indexes for performance optimization and monitoring
    add_index :solid_cache_entries, :byte_size, name: "index_solid_cache_entries_on_byte_size"
    add_index :solid_cache_entries, [:key_hash, :byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    add_index :solid_cache_entries, :key_hash, name: "index_solid_cache_entries_on_key_hash", unique: true
  end
end
