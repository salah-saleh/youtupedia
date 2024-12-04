class HomeController < ApplicationController
  layout :determine_layout

  def index
  end

  private

  def determine_layout
    user_signed_in? ? "dashboard" : "application"
  end
end
