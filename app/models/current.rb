# frozen_string_literal: true

# The Current class provides thread-safe storage for request-specific data using ActiveSupport::CurrentAttributes.
# It maintains contextual data throughout the lifecycle of a request, ensuring thread-safety in a multi-threaded environment.
#
# @example Setting current user
#   Current.user = User.find(1)
#   Current.user # => #<User id: 1, ...>
#
# @example Setting request attributes
#   Current.set_attributes(request)
#
# Attributes:
# - request_id: Unique identifier for the current request
# - user: Currently authenticated user
# - session: Current session data
class Current < ActiveSupport::CurrentAttributes
  attribute :request_id, :user, :session

  class << self
    # Resets all Current attributes and the time zone
    # Called automatically at the end of each request
    #
    # @return [void]
    def reset
      super
      Time.zone = nil
    end

    # Sets the request_id from a request object
    #
    # @param request [ActionDispatch::Request] The current request object
    # @return [String] The request ID
    def set_request_id(request)
      self.request_id = request.request_id
    end

    # Sets the session from a session object
    #
    # @param session [ActionDispatch::Session] The session object
    # @return [ActionDispatch::Session, nil] The session object if present
    def set_session(session)
      return unless session
      self.session = session
    end

    # Sets the current user
    #
    # @param user [User] The user to set as current
    # @return [User, nil] The user object if present
    def set_user(user)
      self.user = user if user
    end

    # Returns the current session ID
    #
    # @return [String, nil] The session ID if a session exists
    def session_id
      session.try(:id)
    end

    # Returns the current session data as a hash
    #
    # @return [Hash, nil] The session data if a session exists
    def session_data
      session.try(:to_h)
    end

    # Helper method to set all attributes from a request object
    # This is typically called at the beginning of each request
    #
    # @param request [ActionDispatch::Request] The current request object
    # @return [void]
    def set_attributes(request)
      set_request_id(request)
      set_session(request.session)
      # User would typically be set in your authentication system
    end
  end
end
