# frozen_string_literal: true

# The RequestTraceable module provides request tracking and logging functionality.
# When included in a controller, it automatically tracks request context, adds request
# tracing through logs, and measures request timing.
#
# Data Flow:
# 1. Request context is captured and stored in Thread.current[:request_context]
# 2. This data is available to all logging calls during the request lifecycle
# 3. The data persists in logs regardless of the formatter used to display it
# 4. Log analysis tools (like logs.rake) can parse this data from the logs
#    independent of how it was formatted when displayed
#
# @example
#   class ApplicationController < ActionController::Base
#     include RequestTraceable
#   end
#
# Features:
# - Automatic request context tracking
# - Request timing measurements
# - Structured logging with request context
# - Request completion logging with timing information
#
# Log Analysis:
# The context data set here can be analyzed by log processing tools even if
# the log formatter doesn't explicitly show all fields. This is because the
# data is stored in the log content itself, not just in its display format.
module RequestTraceable
  extend ActiveSupport::Concern

  included do
    before_action :set_request_context
    prepend_around_action :tag_logs
    before_action :log_request_start
    after_action :log_request_completion
  end

  private

  # Sets up the request context with relevant information from the current request.
  # This context is used for logging and debugging purposes.
  #
  # Important: This method stores the context in Thread.current[:request_context],
  # making it available to:
  # 1. The logging system during the request
  # 2. Log files for later analysis
  # 3. Log processing tools like logs.rake
  #
  # The context includes:
  # - request_id: Unique identifier for the request
  # - session_id: Current session identifier
  # - user_id: ID of the authenticated user (if any)
  # - ip: Client IP address
  # - user_agent: Client user agent string
  # - referer: Request referer
  # - path: Full request path
  # - format: Request format (e.g., :html, :json)
  # - xhr: Whether this is an XHR (AJAX) request
  # - method: HTTP method used
  # - controller: Current controller name
  # - action: Current action name
  #
  # @return [void]
  def set_request_context
    # First ensure we have a request ID in Current
    Current.set_request_id(request)

    @request_context = {
      request_id: Current.request_id,
      session_id: Current.session_id,
      user_id: Current.user&.id,  # This should now be set correctly after authentication
      ip: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      path: request.fullpath,
      format: request.format.symbol,
      xhr: request.xhr?,
      method: request.method,
      controller: controller_name,
      action: action_name
    }

    Thread.current[:request_context] = @request_context
    @request_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Set up tags for the logger with the correct user ID
    begin
      Rails.logger.push_tags(
        "rid=#{@request_context[:request_id]}",
        "sid=#{@request_context[:session_id]}",
        "uid=#{@request_context[:user_id]}",  # This will now show the correct user ID
        "ip=#{@request_context[:ip]}"
      )
    rescue => e
      nil
    end
  end

  # Tags log entries with request context information.
  # While the formatter might not show all context fields,
  # the data remains in the log content for analysis.
  #
  # @yield The controller action to be executed
  # @return [void]
  def tag_logs
    yield
  ensure
    begin
      Rails.logger.pop_tags if @request_context
      Thread.current[:request_context] = nil
    rescue => e
      # Rails.logger.error "Error popping tags: #{e.message}"
      nil
    end
  end

  def log_request_start
    return unless @request_context

    log_info "[#{controller_name}] Request started", context: {
      request_id: @request_context[:request_id],
      session_id: @request_context[:session_id],
      user_id: @request_context[:user_id],
      controller: @request_context[:controller],
      action: @request_context[:action],
      params: params.to_unsafe_h,
      method: @request_context[:method]
    }
  end

  def log_request_completion
    return unless @request_context && @request_start_time

    duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @request_start_time) * 1000
    log_info "[#{controller_name}] Request completed", context: {
      request_id: @request_context[:request_id],
      session_id: @request_context[:session_id],
      user_id: @request_context[:user_id],
      duration_ms: duration.round(2),
      status: response.status,
      content_type: response.content_type
    }
  end

  # We should also update the request context when authentication completes
  def after_authentication
    return unless @request_context

    # Update the user ID in the request context
    @request_context[:user_id] = Current.user&.id

    # Update the logger tags with the new user ID
    Rails.logger.tags.reject! { |tag| tag.start_with?("uid=") }
    begin
      Rails.logger.push_tags("uid=#{@request_context[:user_id]}")
    rescue => e
      nil
    end
  end
end
