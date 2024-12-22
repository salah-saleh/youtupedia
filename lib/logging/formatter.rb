module Logging
  class Formatter < Logger::Formatter
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

    def initialize(colorize: true)
      puts "Initializing Logging::Formatter with colorize=#{colorize}"  # Debug line
      @colorize = colorize
      @tags = []
    end

    def call(severity, timestamp, progname, msg)
      puts "Formatter#call called with: #{severity}, #{msg}"  # Debug line
      timestamp_str = format_timestamp(timestamp)
      severity_str = format_severity(severity)
      message_str = format_message(msg)
      tags_str = @tags.any? ? @tags.join(",") + " " : ""

      "#{timestamp_str} | #{severity_str} | #{tags_str}#{message_str}\n"
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
