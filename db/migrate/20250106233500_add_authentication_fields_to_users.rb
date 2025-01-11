class AddAuthenticationFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :failed_login_attempts, :integer, default: 0, null: false
    add_column :users, :locked_at, :datetime

    add_index :users, :failed_login_attempts
    add_index :users, :locked_at
  end
end
