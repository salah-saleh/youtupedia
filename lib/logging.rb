require_relative "logging/helper"
require_relative "logging/formatter"

# Global logging functionality for the application
module Logging
  class << self
    def included(base)
      base.extend(ClassMethods)
    end
  end

  # Class-level logging methods
  module ClassMethods
    def log_debug(message, object = nil, **options)
      log(:debug, message, object, **options)
    end

    def log_info(message, object = nil, **options)
      log(:info, message, object, **options)
    end

    def log_warn(message, object = nil, **options)
      log(:warn, message, object, **options)
    end

    def log_error(message, object = nil, **options)
      log(:error, message, object, **options)
    end

    private

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

  # Instance-level logging methods
  def log_debug(message, object = nil, **options)
    log(:debug, message, object, **options)
  end

  def log_info(message, object = nil, **options)
    log(:info, message, object, **options)
  end

  def log_warn(message, object = nil, **options)
    log(:warn, message, object, **options)
  end

  def log_error(message, object = nil, **options)
    log(:error, message, object, **options)
  end

  private

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
