# Handles user session management (sign in/out).
# Dependencies:
# - PublicController (for unauthenticated access)
# - User model (for authentication)
# - Session model (for token management)
# - Current object (for session tracking)
#
# Routes:
# - GET /session/new (sign in form)
# - POST /session (create session)
# - DELETE /session (sign out)
class SessionsController < PublicController
  include ActionView::Helpers::TextHelper

  skip_before_action :set_current_request_details, only: [ :create ]

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    @user = find_and_validate_user

    if @user&.locked?
      handle_locked_account
      return
    end

    begin
      @authenticated_user = authenticate_user

      if @authenticated_user
        create_session_and_login(@authenticated_user)
        redirect_back_or_to root_path
      else
        handle_failed_login
      end
    rescue => e
      log_error "Error during session creation", context: { error: e.message }
      handle_failed_login
    end
  end

  def destroy
    Current.session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path, notice: "Signed out successfully!"
  end

  private

  # Finds and validates the user by email
  # @return [User, nil] The user if found, nil otherwise
  def find_and_validate_user
    User.find_by(email_address: params[:email_address]&.downcase)
  end

  # Handles a locked account
  def handle_locked_account
    flash.now[:alert] = "Your account is locked due to too many failed attempts. Please try again in 1 hour or reset your password."
    render :new, status: :unprocessable_entity
  end

  # Authenticates the user with provided credentials
  # @return [User, nil] The authenticated user or nil
  def authenticate_user
    User.authenticate_by(
      email_address: params[:email_address],
      password: params[:password]
    )
  end

  # Creates a new session and sets the login cookie
  # @param user [User] The user to create a session for
  def create_session_and_login(user)
    session = user.sessions.create!(
      expires_at: session_expiry
    )

    set_session_cookie(session)
  end

  # Handles failed login attempts
  def handle_failed_login
    flash.now[:alert] = if @user&.errors&.any?
      @user.errors.full_messages.first
    elsif @user
      "Invalid password. #{pluralize(remaining_attempts(@user), 'attempt')} remaining before account is locked."
    else
      "Invalid email or password."
    end
    render :new, status: :unprocessable_entity
  end

  # Sets the secure session cookie
  # @param session [Session] The session record to use for the cookie
  def set_session_cookie(session)
    cookies.signed[:session_token] = {
      value: session.token,
      expires: session.expires_at,
      httponly: true,  # Prevents JavaScript access to cookie
      secure: Rails.env.production?  # Requires HTTPS in production
    }
  end

  # Calculates session expiry based on remember me preference
  # @return [Time] When the session should expire
  def session_expiry
    params[:remember_me] == "1" ? 30.days.from_now : 24.hours.from_now
  end

  # Calculates remaining login attempts
  # @param user [User] The user to check
  # @return [Integer] Number of attempts remaining
  def remaining_attempts(user)
    max_attempts = 5
    remaining = max_attempts - user.failed_login_attempts
    remaining.positive? ? remaining : 0
  end
end
