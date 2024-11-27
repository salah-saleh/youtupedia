class HomeController < ApplicationController
  layout "dashboard"

  def index
    if user_signed_in?
      render layout: "dashboard"
    else
      render layout: "application"
    end
  end
end
