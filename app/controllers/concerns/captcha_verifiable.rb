module CaptchaVerifiable
  extend ActiveSupport::Concern

  included do
    helper_method :captcha_enabled?
  end

  # Returns true if reCAPTCHA should be enforced for this request
  def captcha_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("ENABLE_RECAPTCHA", "false"))
  end

  # Wraps recaptcha verification, returns true when disabled
  def verify_recaptcha_if_enabled
    return true unless captcha_enabled?
    verify_recaptcha
  end
end


