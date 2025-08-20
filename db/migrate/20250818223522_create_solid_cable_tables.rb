class CreateSolidCableTables < ActiveRecord::Migration[8.0]
  def change
    # Create solid_cable_messages table for ActionCable/SolidCable
    # This table stores WebSocket messages for real-time communication
    create_table :solid_cable_messages, force: :cascade do |t|
      # Binary channel identifier (limited to 1024 bytes for performance)
      t.binary :channel, limit: 1024, null: false
      
      # Binary payload containing the actual message data (limited to 512MB)
      t.binary :payload, limit: 536870912, null: false
      
      # Timestamp when the message was created
      t.datetime :created_at, null: false
      
      # Hash of the channel for efficient indexing and lookups
      t.integer :channel_hash, limit: 8, null: false
    end

    # Add indexes for performance optimization
    add_index :solid_cable_messages, :channel, name: "index_solid_cable_messages_on_channel"
    add_index :solid_cable_messages, :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
    add_index :solid_cable_messages, :created_at, name: "index_solid_cable_messages_on_created_at"
  end
end
