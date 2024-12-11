if Rails.env.production?
  # Create a custom formatter for structured logs
  class StructuredLogFormatter
    def call(severity, time, progname, msg)
      return if msg.nil?

      log_hash = {
        timestamp: time.strftime("%Y-%m-%d %H:%M:%S.%3N"),
        level: severity,
        pid: Process.pid,
        thread: Thread.current.object_id.to_s(36)[0..7]
      }

      # Extract component and message if available
      if msg.to_s =~ /\[(.*?)\](.*)/
        log_hash[:component] = $1.strip
        log_hash[:message] = $2.strip
      else
        log_hash[:message] = msg.to_s
      end

      # Handle exceptions
      if msg.is_a?(Exception)
        log_hash.merge!(
          error_class: msg.class.name,
          error_message: msg.message,
          backtrace: msg.backtrace&.first(3)
        )
      end

      "#{log_hash.to_json}\n"
    end
  end

  # Use structured logging for production.log
  structured_logger = ActiveSupport::Logger.new(
    Rails.root.join("log/structured.log"),
    "daily",
    10.megabytes
  )
  structured_logger.formatter = StructuredLogFormatter.new
end
