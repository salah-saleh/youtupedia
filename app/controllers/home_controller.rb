class HomeController < ApplicationController
  def index
    redirect_to summaries_path if user_signed_in?
  end

  private
end
