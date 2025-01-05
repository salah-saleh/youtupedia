class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_required?

  # Admin functionality
  scope :admins, -> { where(admin: true) }

  def make_admin!
    update!(admin: true)
  end

  def remove_admin!
    update!(admin: false)
  end

  private

  def password_required?
    new_record? || password.present?
  end
end
