class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:about, :contact, :discover]

  def about
  end

  def contact
  end

  def discover
  end
end 