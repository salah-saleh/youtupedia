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
    @admin_mode = session[:admin_mode]
    @users = User.all if @admin_mode
  end

  def create
    if params[:admin_pass] == "pass123"
      session[:admin_mode] = true
      redirect_to settings_path, notice: "Admin mode enabled"
    else
      session[:admin_mode] = false
      redirect_to settings_path, alert: "Invalid admin password"
    end
  end
end
