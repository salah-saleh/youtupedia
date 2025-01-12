class Session < ApplicationRecord
  belongs_to :user

  before_create do
    self.token = generate_unique_token
    self.expires_at ||= 30.days.from_now
  end

  def expired?
    expires_at < Time.current
  end

  private

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64
      break token unless Session.exists?(token: token)
    end
  end
end
