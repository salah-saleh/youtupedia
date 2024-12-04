module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_session
    helper_method :logged_in?
  end

  private

  def authenticate!
    redirect_to new_session_path, alert: "Please sign in to continue" unless logged_in?
  end

  def logged_in?
    Current.session.present?
  end

  def set_current_session
    Current.session = Session.find_by(token: cookies.signed[:session_token]) if cookies.signed[:session_token]
  end
end
