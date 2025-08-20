namespace :users do
  desc "Copy users from storage/development.sqlite3 (SQLite) into current Postgres development DB"
  task copy_from_sqlite: :environment do
    # Define a lightweight model bound to the SQLite development database
    class SqliteUser < ActiveRecord::Base
      self.table_name = "users"

      # Establish a direct connection to the SQLite file under storage/
      establish_connection(
        adapter: "sqlite3",
        database: Rails.root.join("storage", "development.sqlite3").to_s,
        pool: 2,
        timeout: 5000
      )
    end

    puts "Starting users copy from SQLite → Postgres"

    # Basic sanity check: ensure the target model is backed by Postgres
    target_conn = ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
    unless target_conn.to_s.include?("postgres")
      abort "Aborting: target ActiveRecord connection is not PostgreSQL (#{target_conn.inspect})"
    end

    total = SqliteUser.count
    puts "Found #{total} users in SQLite"

    copied = 0
    skipped = 0
    errors = 0

    # Copy in batches to limit memory usage
    SqliteUser.in_batches(of: 500) do |relation|
      relation.each do |su|
        begin
          # Find or initialize the target record by id to preserve primary keys
          u = ::User.find_or_initialize_by(id: su.id)

          # Assign all expected attributes explicitly to avoid mass-assignment surprises
          u.email_address = su[:email_address]
          u.password_digest = su[:password_digest]
          u.admin = su[:admin]
          u.failed_login_attempts = su[:failed_login_attempts]
          u.locked_at = su[:locked_at]
          u.email_verification_token = su[:email_verification_token]
          u.email_verification_sent_at = su[:email_verification_sent_at]
          u.email_verified_at = su[:email_verified_at]
          u.password_reset_token = su[:password_reset_token]
          u.password_reset_sent_at = su[:password_reset_sent_at]

          # Preserve timestamps
          u.created_at = su[:created_at]
          u.updated_at = su[:updated_at]

          # Skip validations to ensure a faithful copy (password presence, etc.)
          if u.changed?
            u.save!(validate: false)
            copied += 1
          else
            skipped += 1
          end
        rescue => e
          errors += 1
          warn "Failed to copy user id=#{su.id} email=#{su[:email_address].inspect}: #{e.class}: #{e.message}"
        end
      end
    end

    # Ensure the users_id_seq is aligned with the highest id
    if ActiveRecord::Base.connection.respond_to?(:reset_pk_sequence!)
      ActiveRecord::Base.connection.reset_pk_sequence!("users")
    end

    puts "Copy complete: copied=#{copied}, skipped=#{skipped}, errors=#{errors} (from total=#{total})"
  end
end


