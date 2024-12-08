class HomeController < ApplicationController
  layout :determine_layout

  def index
    redirect_to summaries_path if user_signed_in?
  end

  private
end
