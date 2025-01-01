require_relative "logging/helper"
require_relative "logging/formatter"

# The Logging module provides a comprehensive logging system for the application.
# It includes both class-level and instance-level logging methods with support for:
# - Multiple log levels (debug, info, warn, error)
# - Structured logging with context data
# - Object truncation for large data structures
# - Component-based logging with automatic class name detection
#
# Object.include Logging will include the logging methods in all objects.
#
# Features:
# - Automatic component detection from class names
# - Context data support for structured logging
# - Configurable truncation for large objects
# - Thread-safe logging implementation
# - Support for both class and instance methods
module Logging
  # Common logging functionality shared between class and instance methods
  module LoggingMethods
    # Logs a debug message with optional object and context
    def log_debug(message, object = nil, **options)
      log(:debug, message, object, **options)
    end

    # Logs an info message with optional object and context
    def log_info(message, object = nil, **options)
      log(:info, message, object, **options)
    end

    # Logs a warning message with optional object and context
    def log_warn(message, object = nil, **options)
      log(:warn, message, object, **options)
    end

    # Logs an error message with optional object and context
    def log_error(message, object = nil, **options)
      log(:error, message, object, **options)
    end

    private

    def log(level, message, object = nil, **options)
      logger = Rails.logger
      # For class methods, self is the class. For instance methods, we need to get the class
      component = self.is_a?(Class) ? name : self.class.name
      component = component.split("::").last

      # Extract truncation options and context data
      truncate_options = options.delete(:truncate) || {}
      context = options.delete(:context) || {}

      # Build the log message
      msg_parts = [ "[#{component}] #{message}" ]

      # Add truncated object if present
      if object
        truncated = Helper.truncate_for_log(object, **truncate_options)
        msg_parts << truncated
      end

      # Add context data if present
      unless context.empty?
        context_str = Helper.truncate_for_log(context)
        msg_parts << context_str
      end

      # Join all parts with proper separators
      logger.send(level, msg_parts.join(" | "))
    end
  end

  # Once the Logging module is included in a class, base.extend will extend the class with the ClassMethods.
  # So now the class has the class-level logging methods, and the instance has the instance-level logging methods.
  # The Singleton Class Pattern is used to ensure that the class-level logging methods are only defined once.
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
  end

  # Class-level logging methods
  module ClassMethods
    include LoggingMethods
  end

  # Include the same methods for instance-level logging
  include LoggingMethods
end

# Include logging in Object to make it globally available
Object.include Logging
