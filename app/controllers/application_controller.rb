class ApplicationController < ActionController::Base
  helper_method :user_signed_in?

  def user_signed_in?
    # Mock logic for now
    # Replace with actual authentication logic
    # session[:user_id].present?
    true
  end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
