# Handles user settings and admin functionality, including:
# - User profile settings
# - Password management
# - Admin user management
# - User impersonation for admins
#
# Security:
# - Requires authentication for all actions
# - Admin-only actions are protected
# - Impersonation maintains original admin session
class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_users, if: :admin_access?

  # GET /settings
  # Shows the settings page with:
  # - Password management section
  # - Admin section (if user is admin)
  # - User management (if admin)
  def index
  end

  # POST /settings
  # Handles various settings actions:
  # - Admin toggling for users (admin only)
  # - User impersonation (admin only)
  # - Exit impersonation
  def create
    if params[:exit_impersonation]
      handle_exit_impersonation
    elsif params[:switch_to_user] && admin_access?
      handle_user_switch
    elsif params[:user_id] && params[:admin_action] && Current.user&.admin?
      handle_admin_toggle
    else
      redirect_to settings_path
    end
  end

  private

  # Loads all users for admin view
  # Only called when user has admin access
  def load_users
    @users = User.all.order(:email_address)
  end

  # Checks if user has admin access
  # True if user is admin or in admin impersonation mode
  def admin_access?
    Current.user&.admin? || session[:admin_impersonation]
  end

  # Handles toggling admin status for users
  # Only accessible by actual admins (not impersonated)
  def handle_admin_toggle
    return unless Current.user&.admin?

    user = User.find_by(id: params[:user_id])
    return unless user

    if params[:admin_action] == "add"
      user.update(admin: true)
      flash[:notice] = "Admin privileges granted to #{user.email_address}"
    elsif params[:admin_action] == "remove"
      user.update(admin: false)
      flash[:notice] = "Admin privileges removed from #{user.email_address}"
    end

    redirect_to settings_path
  end

  # Handles switching to another user (impersonation)
  # Stores original admin session for later restoration
  def handle_user_switch
    new_user = User.find_by(id: params[:switch_to_user])
    return unless new_user

    # Store the original admin's session token
    unless session[:admin_impersonation]
      session[:original_admin_token] = cookies.signed[:session_token]
      session[:admin_impersonation] = true
    end

    # Create a new session for the target user
    user_session = new_user.sessions.create!(
      token: SecureRandom.hex(32),
      expires_at: 30.days.from_now
    )

    # Store the impersonation session token to clean it up later
    session[:impersonation_token] = user_session.token

    # Set the new session token
    cookies.signed[:session_token] = {
      value: user_session.token,
      expires: user_session.expires_at,
      httponly: true
    }

    redirect_to settings_path, notice: "Switched to #{new_user.email_address}"
  end

  # Handles exiting impersonation mode
  # Restores original admin session and cleans up impersonation
  def handle_exit_impersonation
    return unless session[:admin_impersonation]

    if session[:original_admin_token].present?
      # Clean up the impersonation session before restoring original
      if session[:impersonation_token].present?
        Session.find_by(token: session[:impersonation_token])&.destroy
        session.delete(:impersonation_token)
      end

      # Restore the original admin's session
      cookies.signed[:session_token] = {
        value: session[:original_admin_token],
        expires: 30.days.from_now,
        httponly: true
      }

      # Clear the stored admin token
      session.delete(:original_admin_token)
    end

    # Clear the admin impersonation flag
    session.delete(:admin_impersonation)

    redirect_to settings_path, notice: "Exited admin impersonation mode"
  end
end
