class Session < ApplicationRecord
  belongs_to :user

  before_create do
    self.token = SecureRandom.urlsafe_base64
    self.expires_at ||= 30.days.from_now
  end

  def expired?
    expires_at < Time.current
  end
end
