module Logging
  # The Formatter class provides custom log formatting functionality.
  # It handles the formatting of log messages, ensuring consistent output
  # across different log levels and message types.
  #
  # Features:
  # - Consistent log message formatting
  # - Support for structured data in logs
  # - Configurable value truncation (via Helper)
  # - Special handling for hash-like messages
  # - Component-based message prefixing
  # - Colorized output for different severity levels
  #
  # Log Format:
  # The formatter produces logs in the following format:
  # [Component] Message | key1=value1, key2=value2, ...
  #
  # @example Basic log message
  #   [UserService] User created | id=123, email="user@example.com"
  #
  # @example Structured data log
  #   [AuthService] Login attempt | status="failed", attempts=3, ip="192.168.1.1"
  #
  # @example Message with truncated values
  #   [DataService] Data processed | data="very long string...", size=1024
  class Formatter < Logger::Formatter
    # Color codes for different severity levels
    SEVERITY_COLORS = {
      "DEBUG" => "\e[34m", # Blue
      "INFO"  => "\e[32m", # Green
      "WARN"  => "\e[33m", # Yellow
      "ERROR" => "\e[31m", # Red
      "FATAL" => "\e[35m"  # Magenta
    }.freeze

    # Color for component names (Orange)
    COMPONENT_COLOR = "\e[38;5;208m".freeze
    # Color for request tags (Light Blue)
    TAG_COLOR = "\e[38;5;39m".freeze

    RESET_COLOR = "\e[0m".freeze
    COMPONENT_WIDTH = 35
    SEVERITY_WIDTH = 5

    # Initialize the formatter with color option
    #
    # @param colorize [Boolean] Whether to colorize the output
    def initialize(colorize: true)
      super()
      @colorize = colorize
      @tags = []
    end

    # Formats a log message with optional structured data
    #
    # @param severity [String] The log severity level
    # @param timestamp [Time] The timestamp of the log message
    # @param progname [String] The program name (unused)
    # @param msg [String, Hash] The message to format
    # @return [String] The formatted log message
    def call(severity, timestamp, progname, msg)
      # Not needing timestamp
      # timestamp_str = format_timestamp(timestamp)
      severity_str = format_severity(severity)
      message_str = format_message(msg)

      # Format tags if present
      tags_str = format_tags(@tags) if @tags.any?

      parts = [ severity_str ]
      parts << tags_str if tags_str
      parts << message_str

      "#{parts.join(' | ')}\n"
    end

    # Required by ActiveSupport::TaggedLogging
    def push_tags(*tags)
      @tags.concat(tags.flatten)
    end

    # Required by ActiveSupport::TaggedLogging
    def pop_tags(count = 1)
      count.times { @tags.pop }
    end

    # Required by ActiveSupport::TaggedLogging
    def clear_tags!
      @tags.clear
    end

    # Required by ActiveSupport::TaggedLogging
    def current_tags
      @tags.dup
    end

    # Required by ActiveSupport::TaggedLogging
    def tagged(*new_tags)
      new_tags = new_tags.flatten
      if new_tags.any?
        push_tags(new_tags)
        yield self
      else
        yield self
      end
    ensure
      pop_tags(new_tags.size)
    end

    private

    # Formats tags for output
    #
    # @param tags [Array<String>] The tags to format
    # @return [String] The formatted tags
    def format_tags(tags)
      return nil if tags.empty?

      formatted_tags = tags.map do |tag|
        if @colorize
          "#{TAG_COLOR}#{tag}#{RESET_COLOR}"
        else
          tag.to_s
        end
      end.join(" ")

      formatted_tags
    end

    # Formats a timestamp for log output
    #
    # @param timestamp [Time] The timestamp to format
    # @return [String] The formatted timestamp
    def format_timestamp(timestamp)
      timestamp.strftime("%Y-%m-%d %H:%M:%S.%3N")
    end

    # Formats the severity level with optional color
    #
    # @param severity [String] The severity level
    # @return [String] The formatted severity
    def format_severity(severity)
      formatted = severity.ljust(SEVERITY_WIDTH)
      return formatted unless @colorize
      "#{SEVERITY_COLORS[severity]}#{formatted}#{RESET_COLOR}"
    end

    # Formats a message, handling both string and hash inputs
    #
    # @param msg [String, Hash] The message to format
    # @return [String] The formatted message
    def format_message(msg)
      case msg
      when Exception
        format_exception(msg)
      when String
        format_string_message(msg)
      when Hash
        format_hash_message(msg)
      else
        Helper.truncate_for_log(msg)
      end
    end

    def format_exception(error)
      [
        "#{error.class.name}: #{error.message}",
        error.backtrace&.first(3)&.map { |line| "  #{line}" }
      ].flatten.join("\n")
    end

    # Formats a string message, handling component prefixes
    #
    # @param msg [String] The message to format
    # @return [String] The formatted message
    def format_string_message(msg)
      # Handle standard [Component] format
      if msg =~ /\[(.*?)\](.*)/
        component_name = $1
        message = $2.strip
        component = format_component(component_name)
        format_message_with_component(component, message)
      # Handle "MONGODB |" or similar internal formats
      elsif msg =~ /^(\w+)\s*\|(.*)/ || msg =~ /^(\w+):(\d+)\s+(.*)/
        component_name = $1
        message = $2 || $3
        component = format_component(component_name)
        format_message_with_component(component, message)
      else
        msg
      end
    end

    # Formats a message with its component
    #
    # @param component [String] The formatted component name
    # @param message [String] The message to format
    # @return [String] The formatted message
    def format_message_with_component(component, message)
      message = message.strip
      # Check if the message contains a hash
      if message.start_with?("{") && message.end_with?("}")
        # Extract the hash part
        hash_str = message[1..-2].strip

        # Convert Ruby hash syntax to key=value pairs
        pairs = hash_str.split(/,\s*/).map do |pair|
          if pair =~ /(\w+):\s*(.+)/
            key = $1
            value = $2.strip
            "#{key}=#{Helper.truncate_for_log(value)}"
          else
            pair
          end
        end

        "#{component} | #{pairs.join(', ')}"
      else
        "#{component} | #{message}"
      end
    end

    # Formats a component name with color and padding
    #
    # @param component_name [String] The name of the component
    # @return [String] The formatted component name
    def format_component(component_name)
      padded = component_name.ljust(COMPONENT_WIDTH)
      return padded unless @colorize
      "#{COMPONENT_COLOR}#{padded}#{RESET_COLOR}"
    end

    # Formats a hash message into a string
    #
    # @param hash [Hash] The hash to format
    # @return [String] The formatted hash as a string
    def format_hash_message(hash)
      return "" unless hash.is_a?(Hash)

      # Format all pairs, truncating long values
      formatted_pairs = hash.map do |key, value|
        formatted_value = Helper.truncate_for_log(value)
        "#{key}=#{formatted_value}"
      end

      formatted_pairs.join(", ")
    end
  end
end
