# Authentication module provides user authentication and session management.
# Dependencies:
# - Current object (thread-local storage for request context)
# - Session model (handles user sessions)
# - User model (through Current.user)
# - Cookie-based authentication (session_token)
#
# Usage:
# This module is included in ApplicationController and provides:
# - User authentication via session tokens
# - Current user and session tracking
# - Helper methods for authentication state
# - Automatic redirection for unauthenticated users
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_request_details
    before_action :authenticate_user!
    helper_method :user_signed_in?, :current_user
  end

  private

  def set_current_request_details
    Current.session = authenticate_session
    Current.user = Current.session&.user
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to new_session_path, alert: "Please sign in to continue"
    end
  end

  def authenticate_session
    token = cookies.signed[:session_token]
    Session.find_by(token: token) if token
  end

  def user_signed_in?
    Current.user.present?
  end

  def current_user
    Current.user
  end
end
