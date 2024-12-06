module DevRouteProtection
  extend ActiveSupport::Concern

  included do
    before_action :ensure_admin_access
  end

  private

  def ensure_admin_access
    unless from_settings_with_admin_pass?
      redirect_to root_path, alert: "Not authorized"
    end
  end

  def from_settings_with_admin_pass?
    request.referer&.include?("/settings") &&
    session[:admin_mode] == true
  end
end
