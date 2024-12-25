require_relative "logging/helper"
require_relative "logging/formatter"

# The Logging module provides a comprehensive logging system for the application.
# It includes both class-level and instance-level logging methods with support for:
# - Multiple log levels (debug, info, warn, error)
# - Structured logging with context data
# - Object truncation for large data structures
# - Component-based logging with automatic class name detection
#
# @example Basic usage
#   class MyService
#     include Logging
#
#     def process
#       log_info "Processing started"
#       # ... processing logic ...
#       log_debug "Debug information", some_object
#     end
#   end
#
# @example With context and truncation
#   log_info "User action",
#     { action: "signup", data: large_object },
#     context: { user_id: 123 },
#     truncate: { max_length: 100 }
#
# Features:
# - Automatic component detection from class names
# - Context data support for structured logging
# - Configurable truncation for large objects
# - Thread-safe logging implementation
# - Support for both class and instance methods
module Logging
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
  end

  # Class-level logging methods that can be called directly on classes
  # that include the Logging module.
  #
  # @example
  #   class MyService
  #     include Logging
  #
  #     def self.process_batch
  #       log_info "Processing batch"
  #     end
  #   end
  module ClassMethods
    # Logs a debug message with optional object and context
    #
    # @param message [String] The main log message
    # @param object [Object, nil] Optional object to log (will be truncated)
    # @param options [Hash] Additional options for logging
    # @option options [Hash] :context Additional context data
    # @option options [Hash] :truncate Truncation options
    def log_debug(message, object = nil, **options)
      log(:debug, message, object, **options)
    end

    # Logs an info message with optional object and context
    #
    # @param message [String] The main log message
    # @param object [Object, nil] Optional object to log (will be truncated)
    # @param options [Hash] Additional options for logging
    # @option options [Hash] :context Additional context data
    # @option options [Hash] :truncate Truncation options
    def log_info(message, object = nil, **options)
      log(:info, message, object, **options)
    end

    # Logs a warning message with optional object and context
    #
    # @param message [String] The main log message
    # @param object [Object, nil] Optional object to log (will be truncated)
    # @param options [Hash] Additional options for logging
    # @option options [Hash] :context Additional context data
    # @option options [Hash] :truncate Truncation options
    def log_warn(message, object = nil, **options)
      log(:warn, message, object, **options)
    end

    # Logs an error message with optional object and context
    #
    # @param message [String] The main log message
    # @param object [Object, nil] Optional object to log (will be truncated)
    # @param options [Hash] Additional options for logging
    # @option options [Hash] :context Additional context data
    # @option options [Hash] :truncate Truncation options
    def log_error(message, object = nil, **options)
      log(:error, message, object, **options)
    end

    private

    # Internal method to handle the actual logging
    #
    # @param level [Symbol] The log level (:debug, :info, :warn, :error)
    # @param message [String] The main log message
    # @param object [Object, nil] Optional object to log
    # @param options [Hash] Additional options for logging
    def log(level, message, object = nil, **options)
      logger = Rails.logger
      component = name.split("::").last

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
        context_str = Helper.truncate_for_log(context, max_depth: 1)
        msg_parts << context_str
      end

      # Join all parts with proper separators
      logger.send(level, msg_parts.join(" | "))
    end
  end

  # Instance-level logging methods that can be called from instances
  # of classes that include the Logging module.
  #
  # @example
  #   def process_item
  #     log_info "Processing item", item_data
  #   end

  # Logs a debug message with optional object and context
  #
  # @param message [String] The main log message
  # @param object [Object, nil] Optional object to log (will be truncated)
  # @param options [Hash] Additional options for logging
  # @option options [Hash] :context Additional context data
  # @option options [Hash] :truncate Truncation options
  def log_debug(message, object = nil, **options)
    log(:debug, message, object, **options)
  end

  # Logs an info message with optional object and context
  #
  # @param message [String] The main log message
  # @param object [Object, nil] Optional object to log (will be truncated)
  # @param options [Hash] Additional options for logging
  # @option options [Hash] :context Additional context data
  # @option options [Hash] :truncate Truncation options
  def log_info(message, object = nil, **options)
    log(:info, message, object, **options)
  end

  # Logs a warning message with optional object and context
  #
  # @param message [String] The main log message
  # @param object [Object, nil] Optional object to log (will be truncated)
  # @param options [Hash] Additional options for logging
  # @option options [Hash] :context Additional context data
  # @option options [Hash] :truncate Truncation options
  def log_warn(message, object = nil, **options)
    log(:warn, message, object, **options)
  end

  # Logs an error message with optional object and context
  #
  # @param message [String] The main log message
  # @param object [Object, nil] Optional object to log (will be truncated)
  # @param options [Hash] Additional options for logging
  # @option options [Hash] :context Additional context data
  # @option options [Hash] :truncate Truncation options
  def log_error(message, object = nil, **options)
    log(:error, message, object, **options)
  end

  private

  # Internal method to handle the actual logging
  #
  # @param level [Symbol] The log level (:debug, :info, :warn, :error)
  # @param message [String] The main log message
  # @param object [Object, nil] Optional object to log
  # @param options [Hash] Additional options for logging
  def log(level, message, object = nil, **options)
    logger = Rails.logger
    component = self.class.name.split("::").last

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
      context_str = Helper.truncate_for_log(context, max_depth: 1)
      msg_parts << context_str
    end

    # Join all parts with proper separators
    logger.send(level, msg_parts.join(" | "))
  end
end

# Include logging in Object to make it globally available
Object.include Logging
