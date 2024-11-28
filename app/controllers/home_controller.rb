class HomeController < ApplicationController
  include SummaryLoader

  layout :determine_layout

  def index
    @recent_summaries = load_recent_summaries if user_signed_in?
  end

  private

  def determine_layout
    user_signed_in? ? "dashboard" : "application"
  end
end
