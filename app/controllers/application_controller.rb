class ApplicationController < ActionController::Base
  include Authentication
  helper_method :user_signed_in?
  helper TimeHelper

  def user_signed_in?
    Current.user.present?
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def determine_layout
    user_signed_in? ? "dashboard" : "application"
  end
end
