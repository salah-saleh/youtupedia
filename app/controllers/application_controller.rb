class ApplicationController < ActionController::Base
  include Authentication
  helper TimeHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def determine_layout
    user_signed_in? ? "dashboard" : "application"
  end
end
