class CreateSolidCableMessages < ActiveRecord::Migration[8.0]
  def up
    return if table_exists?(:solid_cable_messages)

    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 512.megabytes, null: false
      t.datetime :created_at, null: false
      t.bigint :channel_hash, null: false
    end

    add_index :solid_cable_messages, :channel
    add_index :solid_cable_messages, :channel_hash
    add_index :solid_cable_messages, :created_at
  end

  def down
    drop_table :solid_cable_messages, if_exists: true
  end
end


