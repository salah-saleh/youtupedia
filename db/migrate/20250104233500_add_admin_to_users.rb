class AddAdminToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :admin, :boolean, default: false, null: false
    add_index :users, :admin
    add_index :users, :email_address
    add_index :sessions, :token
  end
end
