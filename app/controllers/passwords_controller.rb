# Handles password reset functionality for users, including:
# - Requesting password reset emails
# - Verifying reset tokens
# - Setting new passwords
#
# Flow:
# 1. User requests password reset (create)
# 2. User receives email with reset link
# 3. User clicks link and verifies token (edit)
# 4. User sets new password (update)
#
# Security:
# - Reset tokens expire after 4 hours
# - Tokens are signed and verified
# - One-time use tokens (cleared after successful reset)
class PasswordsController < PublicController
  before_action :set_user_by_token, only: [:edit, :update]
  before_action :require_unauthenticated, only: [:new]

  # GET /passwords/new
  # Shows the password reset request form
  # Only accessible when not logged in
  def new
  end

  # POST /passwords
  # Handles password reset requests
  # - From settings page: Uses current user's email
  # - From login page: Uses provided email
  #
  # Params:
  # - email: Email address to send reset instructions to
  def create
    if user = User.find_by(email_address: params[:email]&.downcase)
      user.generate_password_reset_token!
      user.send_password_reset_email

      if Current.user
        redirect_to settings_path, notice: "Check your email for reset instructions"
      else
        redirect_to new_password_path, notice: "Check your email for reset instructions"
      end
    else
      redirect_to new_password_path, alert: "Email address not found"
    end
  end

  # GET /passwords/:token/edit
  # Shows the password reset form if token is valid
  # Redirects to new password request if token is invalid/expired
  def edit
    if @user.nil? || @user.password_reset_token_expired?
      redirect_to new_password_path, alert: "Reset token has expired. Please try again."
    end
  end

  # PATCH /passwords/:token
  # Updates the user's password if token is valid
  #
  # Params:
  # - password: New password
  # - password_confirmation: Confirmation of new password
  def update
    if @user.nil? || @user.password_reset_token_expired?
      redirect_to new_password_path, alert: "Reset token has expired. Please try again."
      return
    end

    if @user.update(password_params)
      @user.clear_password_reset_token!
      redirect_to new_session_path, notice: "Password has been reset successfully. Please sign in."
    else
      flash.now[:alert] = @user.errors.full_messages.first
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Finds and sets the user based on the reset token
  # Verifies token signature and sets @user if valid
  def set_user_by_token
    return if params[:token].blank?

    begin
      @user = User.find_signed(params[:token], purpose: :password_reset)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      # Invalid token, leave @user as nil
    end
  end

  # Permitted parameters for password reset
  def password_params
    params.permit(:password, :password_confirmation)
  end

  # Ensures password reset form is only accessible when not logged in
  # Logged-in users should use the settings page
  def require_unauthenticated
    redirect_to settings_path if Current.user
  end
end
