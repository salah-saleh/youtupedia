# Base class for all services providing common logging functionality
class BaseService
  class << self
    protected

    # Generic error handler for service operations
    # @param error [Exception] The error to handle
    # @param prefix [String] Optional prefix for the error message
    # @return [Hash] Standardized error response
    def handle_error(error, prefix = "Error")
      log_error "#{prefix}: #{error.message}"
      log_error "Full error details", error.full_message
      { success: false, error: "#{prefix}: #{error.message}" }
    end

    def default_cache_namespace
      name.demodulize.underscore.pluralize
    end
  end
end
