module Logging
  class Formatter
    SEVERITY_COLORS = {
      "DEBUG" => "\e[34m", # Blue
      "INFO"  => "\e[32m", # Green
      "WARN"  => "\e[33m", # Yellow
      "ERROR" => "\e[31m", # Red
      "FATAL" => "\e[35m"  # Magenta
    }.freeze

    RESET_COLOR = "\e[0m".freeze
    COMPONENT_WIDTH = 25
    SEVERITY_WIDTH = 5

    def initialize(colorize: false)
      @colorize = colorize
      @tags = []
    end

    def call(severity, timestamp, progname, msg)
      timestamp_str = format_timestamp(timestamp)
      severity_str = format_severity(severity)
      message_str = format_message(msg)
      tags_str = @tags.any? ? @tags.join(",") + " " : ""

      "#{timestamp_str} | #{severity_str} | #{tags_str}#{message_str}\n"
    end

    # Required by ActiveSupport::TaggedLogging
    def push_tags(*tags)
      @tags.concat(tags)
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

    private

    def format_timestamp(timestamp)
      timestamp.strftime("%Y-%m-%d %H:%M:%S.%3N")
    end

    def format_severity(severity)
      formatted = severity.ljust(SEVERITY_WIDTH)
      return formatted unless @colorize
      "#{SEVERITY_COLORS[severity]}#{formatted}#{RESET_COLOR}"
    end

    def format_message(msg)
      case msg
      when Exception
        format_exception(msg)
      when String
        format_string_message(msg)
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

    def format_string_message(msg)
      if msg =~ /\[(.*?)\](.*)/
        component = $1.ljust(COMPONENT_WIDTH)
        message = $2.strip
        "#{component} | #{message}"
      else
        msg
      end
    end
  end
end
