# Handles email verification flow
# Dependencies:
# - PublicController (for unauthenticated access)
# - User model (for verification)
#
# Routes:
# - GET /verify_email/:token (verify email)
# - POST /resend_verification (resend verification email)
class EmailVerificationsController < PublicController
  def verify
    user = User.find_by(email_verification_token: params[:token])

    if user.present? && user.email_verification_sent_at > 24.hours.ago
      user.verify_email!
      redirect_to root_path, notice: "Thank you! Your email has been verified."
    else
      redirect_to root_path, alert: "Invalid or expired verification link. Please request a new one."
    end
  end

  def create
    user = User.find_by(email_address: params[:email])

    if user && !user.email_verified?
      user.send_verification_email
      redirect_to root_path, notice: "Verification email sent. Please check your inbox."
    else
      redirect_to root_path, alert: "Unable to send verification email. Please contact support."
    end
  end
end
