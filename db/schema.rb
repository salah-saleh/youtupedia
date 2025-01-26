# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_06_233501) do
  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token"], name: "index_sessions_on_token"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "email_verification_token"
    t.datetime "email_verification_sent_at"
    t.datetime "email_verified_at"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email_address"], name: "index_users_on_email_address"
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["email_verified_at"], name: "index_users_on_email_verified_at"
    t.index ["failed_login_attempts"], name: "index_users_on_failed_login_attempts"
    t.index ["locked_at"], name: "index_users_on_locked_at"
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token"
  end

  add_foreign_key "sessions", "users"
end
