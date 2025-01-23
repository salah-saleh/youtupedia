class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:about, :contact]

  def about
  end

  def contact
  end
end 