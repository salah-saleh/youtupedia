class MissionControlBaseController < ActionController::Base
  include Authentication
  include RequestTraceable
  allow_browser versions: :modern

  # Use app auth, but avoid the engine's URL defaults
  skip_before_action :authenticate_user!
  before_action :ensure_admin!

  private
    def ensure_admin!
      return if Current.user&.admin?

      # Remember where we were going, then redirect via main_app routes
      store_location if request.get?
      redirect_to main_app.new_session_path, alert: "You must be an admin to access this page."
    end
end


