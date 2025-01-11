class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_secure_password

  # Constants for validation
  PASSWORD_REQUIREMENTS = /\A
    (?=.*\d)           # Must contain at least one number
    (?=.*[a-z])        # Must contain at least one lowercase letter
    (?=.*[A-Z])        # Must contain at least one uppercase letter
    (?=.*[[:^alnum:]]) # Must contain at least one symbol
  /x

  # Validations
  validates :email_address, presence: true,
                          uniqueness: { case_sensitive: false },
                          format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
    length: { minimum: 8, message: "must be at least 8 characters long" },
    format: {
      with: PASSWORD_REQUIREMENTS,
      message: "must include at least one lowercase letter, one uppercase letter, one number, and one symbol"
    },
    if: -> { should_validate_password_strength? }

  # Track failed login attempts and verification
  attribute :failed_login_attempts, :integer, default: 0
  attribute :locked_at, :datetime
  attribute :email_verification_token, :string
  attribute :email_verification_sent_at, :datetime
  attribute :email_verified_at, :datetime

  before_save :downcase_email
  before_create :generate_email_verification_token, if: :email_verification_required?

  # Class methods
  def self.authenticate_by(attributes)
    begin
      # Log the authentication attempt (filtering sensitive data)
      log_info "Authentication attempt", context: {
        email: attributes[:email_address]&.gsub(/.{0,4}@/, '****@')
      }

      return nil if attributes[:email_address].blank? || attributes[:password].blank?

      user = find_by(email_address: attributes[:email_address].downcase)
      return nil unless user

      # Log that we found the user
      log_info "User found", context: {
        user_id: user.id,
        email_verified: user.email_verified?,
        locked: user.locked?,
        password_digest_present: user.password_digest.present?
      }

      # Check if account is locked
      log_info "Checking if account is locked", context: { user_id: user.id }
      if user.locked?
        log_info "Account is locked", context: { user_id: user.id }
        user.errors.add(:base, "Account is locked. Please reset your password or contact support.")
        return nil
      end

      # Check if email is verified
      log_info "Checking if email is verified", context: { user_id: user.id }
      if Rails.configuration.require_email_verification && !user.email_verified? && !Rails.env.development?
        log_info "Email not verified", context: { user_id: user.id }
        user.errors.add(:base, "Please verify your email address. Check your inbox for verification instructions.")
        return nil
      end

      # Check if password_digest exists
      unless user.password_digest.present?
        log_error "Missing password_digest", context: { user_id: user.id }
        user.errors.add(:base, "Invalid login credentials")
        return nil
      end

      log_debug "Starting authentication process", context: {
        user_id: user.id,
        password_digest_present: user.password_digest.present?,
        password_digest_valid: user.password_digest.start_with?("$2a$"),
        password_digest_length: user.password_digest&.length,
        password_digest_preview: user.password_digest&.gsub(/^(.{5}).*(.{5})$/, '\1...\2')
      }

      begin
        authenticated = nil
        begin
          authenticated = user.authenticate(attributes[:password])
        rescue BCrypt::Errors::InvalidHash => e
          log_error "BCrypt invalid hash error", context: {
            user_id: user.id,
            error: e.message,
            password_digest: user.password_digest&.gsub(/^(.{5}).*(.{5})$/, '\1...\2')
          }
          user.errors.add(:base, "Invalid login credentials")
          return nil
        rescue => e
          log_error "Authentication error", context: {
            user_id: user.id,
            error_class: e.class,
            error_message: e.message,
            backtrace: e.backtrace,
            password_digest_present: user.password_digest.present?,
            password_digest_valid: user.password_digest&.start_with?("$2a$"),
            password_digest_preview: user.password_digest&.gsub(/^(.{5}).*(.{5})$/, '\1...\2')
          }
          raise
        end

        if authenticated
          log_info "Authentication successful", context: { user_id: user.id }
          user.update_columns(failed_login_attempts: 0)
          user
        else
          log_info "Authentication failed", context: { user_id: user.id }
          user.failed_login_attempt!
          nil
        end
      rescue => e
        log_error "Unexpected authentication error", context: {
          user_id: user.id,
          error_class: e.class,
          error_message: e.message,
          backtrace: e.backtrace
        }
        raise
      end
    rescue => e
      log_error "Unexpected error in authenticate_by", context: {
        error_class: e.class,
        error_message: e.message,
        backtrace: e.backtrace
      }
      raise
    end
  end

  # Instance methods
  def failed_login_attempt!
    increment!(:failed_login_attempts)

    if failed_login_attempts >= 5
      update_columns(locked_at: Time.current)
    end
  end

  def locked?
    return false if locked_at.nil?

    # Unlock after 1 hour
    if locked_at < 1.hour.ago
      update_columns(locked_at: nil, failed_login_attempts: 0)
      false
    else
      true
    end
  end

  def email_verified?
    email_verified_at.present?
  end

  def verify_email!
    touch(:email_verified_at)
    update_columns(
      email_verification_token: nil,
      email_verification_sent_at: nil
    )
  end

  def generate_verification_token!
    generate_email_verification_token
    save!
    email_verification_token
  end

  def send_verification_email
    generate_verification_token!

    if Rails.env.development?
      UserMailer.with(user: self).email_verification.deliver_now
    else
      UserMailer.with(user: self).email_verification.deliver_later
    end
  end

  private

  def should_validate_password_strength?
    return false unless password_required?
    return false unless Rails.configuration.require_strong_password

    # Only validate strength for new records or password changes
    new_record? || password.present?
  end

  def password_required?
    new_record? || password.present?
  end

  def downcase_email
    self.email_address = email_address.downcase
  end

  def generate_email_verification_token
    return if email_verification_token.present?

    loop do
      self.email_verification_token = SecureRandom.urlsafe_base64(32)
      self.email_verification_sent_at = Time.current
      break unless User.exists?(email_verification_token: email_verification_token)
    end
  end

  def email_verification_required?
    Rails.configuration.require_email_verification
  end
end
