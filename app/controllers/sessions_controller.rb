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
  skip_before_action :set_current_request_details, only: [ :create ]

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
      session = user.sessions.create!
      cookies.signed[:session_token] = { value: session.token, httponly: true }
      redirect_to root_path, notice: "Welcome back!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Current.session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path, notice: "You have been signed out"
  end
end
