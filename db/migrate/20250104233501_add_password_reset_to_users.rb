class AddPasswordResetToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_sent_at, :datetime
    add_index :users, :password_reset_token
  end
end
