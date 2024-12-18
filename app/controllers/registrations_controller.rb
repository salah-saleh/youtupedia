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
    redirect_to root_path if user_signed_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session = @user.sessions.create!
      cookies.signed[:session_token] = { value: session.token, httponly: true }
      redirect_to root_path, notice: "Welcome! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
