class SessionsController < ApplicationController
  skip_before_action :set_current_session, only: [ :create ]
  layout :determine_layout

  def new
    redirect_to root_path if user_signed_in?
    @user = User.new
  end

  def create
    if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
      session = user.sessions.create!
      cookies.signed[:session_token] = { value: session.token, httponly: true }

      # Force a reload of the page to switch layouts
      redirect_to root_path, allow_other_host: true
    else
      redirect_to new_session_path, alert: "Invalid email or password"
    end
  end

  def destroy
    Current.session&.destroy
    cookies.delete(:session_token)
    redirect_to root_path
  end
end
