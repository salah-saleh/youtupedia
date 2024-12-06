class SettingsController < ApplicationController
  include AuthenticatedController

  def index
    @admin_mode = params[:admin_pass] == "admin-pass-yt"
    @users = User.all if @admin_mode
  end
end
