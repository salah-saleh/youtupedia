# Base controller that all other controllers inherit from.
# Dependencies:
# - Authentication module (provides user authentication and session management)
# - Modern browser support (requires browsers with webp, web push, badges, import maps, CSS nesting, and CSS :has)
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Authentication

  before_action :debug_logging

  private

  def debug_logging
    log_debug "Request started", context: {
      controller: controller_name,
      action: action_name,
      params: params.to_unsafe_h,
      method: request.method
    }
  end
end
