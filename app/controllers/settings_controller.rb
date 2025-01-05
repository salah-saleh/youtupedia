# Handles application settings and admin access.
# Dependencies:
# - ApplicationController (requires authentication)
# - User model (for admin user listing)
# - Session-based admin mode
#
# Features:
# - Admin mode toggle with password protection
# - User management interface when in admin mode
#
# Routes:
# - GET /settings (settings page)
# - POST /settings (toggle admin mode)
class SettingsController < ApplicationController
  def index
    @users = User.all if Current.user&.admin?
  end

  def create
    if params[:admin_pass].present?
      # rails credentials:edit
      # admin_password: your_secure_password_here
      # if Rails.application.credentials.admin_password == params[:admin_pass]
      if "pass123" == params[:admin_pass]
        Current.user.make_admin!
        redirect_to settings_path, notice: "Admin access granted"
      else
        redirect_to settings_path, alert: "Invalid admin password"
      end
    elsif params[:admin_mode] == "false" && Current.user&.admin?
      Current.user.remove_admin!
      redirect_to settings_path, notice: "Exited admin mode"
    else
      redirect_to settings_path, alert: "Invalid request"
    end
  end
end
