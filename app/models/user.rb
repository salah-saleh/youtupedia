class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, allow_nil: true, length: { minimum: 8 }

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  def authenticate_session(token)
    sessions.find_by(token: token)
  end
end
