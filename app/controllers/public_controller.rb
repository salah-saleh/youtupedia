# Base controller for public-facing pages that don't require authentication.
# Dependencies:
# - ApplicationController (inherits base functionality)
# - Authentication module (skips authentication requirement)
#
# Usage:
# Inherit from this controller for any routes that should be publicly accessible
# without requiring user authentication.
class PublicController < ApplicationController
  skip_before_action :authenticate_user!
end
