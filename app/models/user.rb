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
    if: -> { password_required? && Rails.configuration.require_strong_password }

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
    return nil if attributes[:email_address].blank? || attributes[:password].blank?

    user = find_by(email_address: attributes[:email_address].downcase)
    return nil unless user

    # Check if account is locked
    if user.locked?
      user.errors.add(:base, "Account is locked. Please reset your password or contact support.")
      return nil
    end

    # Check if email is verified
    if Rails.configuration.require_email_verification && !user.email_verified? && !Rails.env.development?
      user.errors.add(:base, "Please verify your email address. Check your inbox for verification instructions.")
      return nil
    end

    if user.authenticate(attributes[:password])
      user.update_columns(failed_login_attempts: 0)
      user
    else
      user.failed_login_attempt!
      nil
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
