# Handles new user registration.
# Dependencies:
# - PublicController (for unauthenticated access)
# - User model (for account creation)
# - Session model (for automatic sign in)
#
# Routes:
# - GET /registration/new (registration form)
# - POST /registration (create account)
class RegistrationsController < PublicController
  def new
    @user = User.new
  end

  # TODO verify password as it is typed in form
  def create
    @user = User.new(user_params)

    User.transaction do
      if @user.save
        # Send verification email if required
        if Rails.configuration.require_email_verification
          # If email sending fails, it will rollback the transaction
          @user.send_verification_email
          redirect_to root_path, notice: "Thanks for signing up! Please check your email (and spam folder) to verify your account."
        else
          # Auto-verify if not required
          @user.verify_email!

          # Create session for auto-login
          create_session_for_user(@user)
          redirect_to root_path, notice: "Welcome! Your account has been created successfully."
        end
      else
        # Render form again with validation errors
        render :new, status: :unprocessable_entity
      end
    end
  rescue => e
    # Log the error for debugging
    log_error "Failed to create user account", context: { error: e.message }

    # Delete the user if it was created but email failed
    @user.destroy if @user&.persisted?

    # Add a generic error message
    @user.errors.add(:base, "We couldn't create your account at this time. Please try again later.")
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def create_session_for_user(user)
    session = user.sessions.create!(
      token: SecureRandom.hex(32),
      expires_at: 24.hours.from_now
    )

    cookies.signed[:session_token] = {
      value: session.token,
      expires: session.expires_at,
      httponly: true,
      secure: Rails.env.production?
    }
  end
end
