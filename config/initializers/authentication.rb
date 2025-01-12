# Authentication configuration
Rails.application.config.tap do |config|
  # Email verification requirement
  config.require_email_verification = true

  # Strong password requirement
  config.require_strong_password = true

  # Override settings in development
  if Rails.env.development?
    config.require_email_verification = false
    config.require_strong_password = false
  end
end
