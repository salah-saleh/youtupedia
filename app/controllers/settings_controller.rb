# Handles application settings and admin access.
# Dependencies:
# - ApplicationController (requires authentication)
# - User model (for admin user listing)
#
# Features:
# - Admin user management
# - User switching with admin privilege preservation
#
# Routes:
# - GET /settings (settings page)
# - POST /settings (admin actions)
class SettingsController < ApplicationController
  before_action :require_admin, except: [ :index ]

  def index
    @users = User.all if Current.user&.admin? || session[:admin_impersonation]
  end

  def create
    if params[:user_id].present? && params[:admin_action].present?
      handle_admin_toggle
    elsif params[:switch_to_user].present?
      handle_user_switch
    elsif params[:exit_impersonation].present?
      handle_exit_impersonation
    else
      redirect_to settings_path, alert: "Invalid request"
    end
  end

  private

  def require_admin
    unless Current.user&.admin? || session[:admin_impersonation]
      redirect_to settings_path, alert: "Admin access required"
    end
  end

  def handle_admin_toggle
    return unless Current.user&.admin? # Only real admins can toggle admin status

    user = User.find(params[:user_id])

    case params[:admin_action]
    when "add"
      user.make_admin!
      redirect_to settings_path, notice: "Admin access granted to #{user.email_address}"
    when "remove"
      # Prevent removing the last admin
      if User.admins.count == 1 && user.admin?
        redirect_to settings_path, alert: "Cannot remove the last admin user"
        return
      end

      user.remove_admin!
      redirect_to settings_path, notice: "Admin access removed from #{user.email_address}"
    end
  end

  def handle_user_switch
    return unless Current.user&.admin? || session[:admin_impersonation]

    new_user = User.find(params[:switch_to_user])

    # If switching to the original admin user, treat it as exiting impersonation
    if new_user.admin? && session[:original_admin_token].present?
      handle_exit_impersonation
      return
    end

    # Store the original admin's session token before switching
    session[:original_admin_token] = cookies.signed[:session_token] if Current.user.admin?

    # Store admin impersonation state if switching from an admin user
    session[:admin_impersonation] = true if Current.user.admin?

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
