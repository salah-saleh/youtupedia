# Home page controller that provides the landing page and public features.
# Dependencies:
# - ApplicationController (inherits base functionality)
# - Authentication module (for optional user context)
class HomeController < ApplicationController
  public_actions :index

  def index
  end
end
