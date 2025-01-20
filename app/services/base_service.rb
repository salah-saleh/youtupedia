# Base class for all services providing common logging functionality
class BaseService
  class << self
    # Generic error handler for service operations
    # @param error [Exception] The error to handle
    # @param prefix [String] Optional prefix for the error message
    # @return [Hash] Standardized error response
    def handle_error(error, prefix = "Error")
      log_error "#{prefix}: #{error.message}", context: {
        error: error.message,
        backtrace: error.backtrace&.first(5)
      }

      {
        success: false,
        error: "#{prefix}: #{error.message}"
      }
    end

    def default_cache_namespace
      name.demodulize.underscore.pluralize
    end
  end

  def handle_error(error, prefix = "Error")
    self.class.handle_error(error, prefix)
  end
end
