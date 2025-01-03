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
# - Configurable authentication requirements per controller/action
module Authentication
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_current_request_details
    before_action :authenticate_user!
    helper_method :user_signed_in?, :current_user
  end

  class_methods do
    def public_actions(*actions)
      # Handle both array and splat arguments
      actions = actions.first if actions.length == 1 && actions.first.is_a?(Array)
      skip_before_action :authenticate_user!, only: actions
    end
  end

  private

  def set_current_request_details
    Current.session = authenticate_session
    Current.user = Current.session&.user
    after_authentication if respond_to?(:after_authentication)
  end

  def authenticate_user!
    unless user_signed_in?
      store_location
      redirect_to new_session_path
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

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def redirect_back_or_to(default)
    redirect_to(session.delete(:return_to) || default)
  end
end
