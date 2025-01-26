class AddExpiresAtIndexToSessions < ActiveRecord::Migration[8.0]
  def change
    add_index :sessions, :expires_at
  end
end 