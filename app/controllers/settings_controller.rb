class SettingsController < ApplicationController
  include AuthenticatedController

  def index
    if params[:admin_pass] == "pass123"
      session[:admin_mode] = true
      @admin_mode = true
    else
      session[:admin_mode] = false
      @admin_mode = false
    end
    @users = User.all if @admin_mode
  end
end
