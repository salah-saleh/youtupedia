# Log Analysis Tasks
#
# This file provides rake tasks for real-time log watching and analysis.
# The analysis works independently of how logs are formatted for display
# because it processes the underlying log data, not its presentation.
#
# Data Flow:
# 1. Logs contain request context from RequestTraceable
# 2. This data is stored in either JSON format or standard Rails log format
# 3. The analysis parses both formats to extract meaningful data
# 4. The formatter used to display logs doesn't affect this analysis
#
# Available Tasks:
# - rake logs:watch   - Watch and analyze logs in real-time
# - rake logs:analyze - Analyze logs from a file
# - rake logs:test    - Test log processing
#
# Environment Variables:
# - DEBUG: Enable debug output
# - HEROKU: Use Heroku logs instead of local
# - LOG_FILE: Specify alternative log file
# - LINES: Number of lines to analyze (Heroku only)
namespace :logs do
  desc "Watch and analyze logs in real-time"
  task :watch do
    require "json"

    if ENV["HEROKU"]
      watch_heroku_logs
    else
      watch_development_logs
    end
  end

  desc "Analyze logs from a file"
  task :analyze do
    require "json"

    if ENV["HEROKU"]
      analyze_heroku_logs
    else
      analyze_development_logs
    end
  end

  desc "Test log processing"
  task test: :environment do
    stats = initialize_stats

    # Sample log entries
    sample_logs = [
      'Started GET "/posts" for 127.0.0.1',
      "Processing by PostsController#index as HTML",
      "Completed 200 OK in 50ms"
    ]

    puts "Testing log processing..."
    sample_logs.each do |line|
      case line
      when /Started/
        process_rails_log_entry(line, stats)
      when /Completed/
        process_rails_completion(line, stats)
      end
    end

    puts "\nProcessing results:"
    display_stats(stats)
  end

  private

  def watch_heroku_logs
    puts "Watching Heroku logs..."
    IO.popen("heroku logs --tail") do |io|
      io.each do |line|
        begin
          entry = JSON.parse(line)
          print_formatted_entry(entry)
        rescue JSON::ParserError
          print line # Print non-JSON logs as-is
        end
      end
    end
  end

  def watch_development_logs
    stats = initialize_stats
    puts "Watching development logs..."

    begin
      File.open("log/development.log", "r") do |log|
        log.seek(0, IO::SEEK_END)
        loop do
          while line = log.gets
            puts "Got log line: #{line}" if ENV["DEBUG"]

            begin
              # Try parsing as JSON first
              entry = JSON.parse(line)
              process_entry(entry, stats)
            rescue JSON::ParserError
              # Handle Rails standard log format
              case line
              when /Started (\w+) "([^"]+)"/
                puts "Found request: #{line}" if ENV["DEBUG"]
                process_rails_log_entry(line, stats)
              when /Completed (\d+)/
                puts "Found completion: #{line}" if ENV["DEBUG"]
                process_rails_completion(line, stats)
              end
            end
          end

          display_stats(stats)
          sleep 0.1
        end
      end
    rescue Interrupt
      puts "\nFinal Statistics:"
      display_stats(stats)
    end
  end

  def analyze_heroku_logs
    puts "Analyzing Heroku logs..."
    logs = `heroku logs -n #{ENV.fetch("LINES", 1000)}`
    analyze_log_content(logs)
  end

  def analyze_development_logs
    puts "Analyzing development logs..."
    log_file = ENV["LOG_FILE"] || "log/development.log"
    analyze_log_content(File.read(log_file))
  end

  def initialize_stats
    {
      requests: {},
      errors: [],
      response_times: [],
      start_time: Time.now
    }
  end

  def process_new_logs(log, stats)
    while line = log.gets
      begin
        # Try parsing as JSON first
        entry = JSON.parse(line)
        process_entry(entry, stats)
      rescue JSON::ParserError
        # Add debug output
        puts "Processing standard log: #{line}" if ENV["DEBUG"]

        # Handle standard Rails log formats
        case line
        when /Started (\w+) "([^"]+)"/
          process_rails_log_entry(line, stats)
        when /Completed (\d+)/
          process_rails_completion(line, stats)
        end
      end
    end
  end

  # Processes both JSON-formatted and standard Rails logs.
  # This flexibility allows the analysis to work regardless of:
  # 1. The formatter used to display logs
  # 2. The log format (JSON or standard Rails)
  # 3. The presence or absence of specific fields in the display
  #
  # @param entry [String, Hash] The log entry to process
  # @param stats [Hash] The statistics hash to update
  def process_entry(entry, stats)
    # Handle both string and parsed JSON input
    entry = JSON.parse(entry) if entry.is_a?(String)

    # Skip if not a parseable log entry
    return unless entry.is_a?(Hash)
    return unless entry["request_id"] || entry["message"]&.include?("Started")

    # Handle Rails default logs
    if entry["message"]&.include?("Started")
      match = entry["message"].match(/Started (\w+) "([^"]+)"/)
      return unless match

      request_id = SecureRandom.uuid # Generate ID for non-JSON logs
      stats[:requests][request_id] ||= {
        path: match[2],
        method: match[1],
        start_time: entry["timestamp"] || Time.now,
        status: nil,
        duration: nil
      }
    end

    # Handle JSON-formatted logs
    if entry["request_id"]
      stats[:requests][entry["request_id"]] ||= {
        path: entry["path"],
        method: entry["method"],
        start_time: entry["timestamp"] ? Time.parse(entry["timestamp"]) : Time.now,
        status: nil,
        duration: nil
      }

      if entry["event"] == "request_completed"
        request = stats[:requests][entry["request_id"]]
        request[:status] = entry["status"]
        request[:duration] = entry["duration_ms"]
        stats[:response_times] << entry["duration_ms"] if entry["duration_ms"]
      end
    end

    # Track errors regardless of format
    if entry["level"] == "ERROR" || entry["message"]&.include?("ERROR")
      stats[:errors] << entry
    end
  rescue => e
    puts "Warning: Could not process log entry: #{e.message}"
  end

  # Processes standard Rails log format entries.
  # This works independently of the formatter because it looks for
  # specific patterns in the log content, not its display format.
  #
  # @param line [String] The log line to process
  # @param stats [Hash] The statistics hash to update
  def process_rails_log_entry(line, stats)
    if match = line.match(/Started (\w+) "([^"]+)"/)
      request_id = SecureRandom.uuid
      method = match[1]
      path = match[2]

      puts "Processing request: #{method} #{path}" if ENV["DEBUG"]

      # Skip asset requests in statistics
      return if path.start_with?("/assets/", "/packs/")

      stats[:requests][request_id] ||= {
        path: path,
        method: method,
        start_time: Time.now,
        status: nil,
        duration: nil
      }
    end
  rescue => e
    puts "Warning: Could not process Rails log entry: #{line}"
    puts "Error: #{e.message}"
    puts e.backtrace if ENV["DEBUG"]
  end

  def process_rails_completion(line, stats)
    if match = line.match(/Completed (\d+).*?in (\d+(?:\.\d+)?)ms/)
      status = match[1].to_i
      duration = match[2].to_f

      puts "Processing completion: status=#{status}, duration=#{duration}" if ENV["DEBUG"]

      # Find the most recent uncompleted request
      request = stats[:requests].values.reverse.find { |r| r[:status].nil? }
      if request
        puts "Completing request: #{request[:method]} #{request[:path]} (#{status})" if ENV["DEBUG"]

        request[:status] = status
        request[:duration] = duration
        stats[:response_times] << duration
      else
        puts "Warning: Found completion but no matching request" if ENV["DEBUG"]
      end
    end
  rescue => e
    puts "Warning: Could not process Rails completion: #{line}"
    puts "Error: #{e.message}"
    puts e.backtrace if ENV["DEBUG"]
  end

  def print_formatted_entry(entry)
    color = case entry["level"]
    when "ERROR" then "\e[31m" # red
    when "WARN"  then "\e[33m" # yellow
    when "INFO"  then "\e[32m" # green
    else "\e[0m"               # default
    end
    puts "#{color}[#{entry['timestamp']}] #{entry['level']}: #{entry['message']}\e[0m"
  end

  def display_stats(stats)
    print "\e[H\e[2J" # Clear screen
    print_summary(stats)
    print_recent_requests(stats)
    print_recent_errors(stats)
  end

  def print_summary(stats)
    total_requests = stats[:requests].count
    completed_requests = stats[:requests].count { |_, r| r[:status] }
    error_count = stats[:errors].count
    avg_response = stats[:response_times].empty? ? 0 : stats[:response_times].sum / stats[:response_times].size

    puts "=== Live Log Analysis ==="
    puts "Running for: #{(Time.now - stats[:start_time]).to_i}s"
    puts "\nSummary:"
    puts "  Total Requests: #{total_requests}"
    puts "  Completed: #{completed_requests}"
    puts "  Pending: #{total_requests - completed_requests}"
    puts "  Errors: #{error_count}"
    puts "  Avg Response: #{avg_response.round(2)}ms"

    # Add status code breakdown with proper sorting
    if completed_requests > 0
      puts "\nStatus Codes:"
      status_counts = stats[:requests].values
                                    .map { |r| r[:status] }
                                    .compact
                                    .group_by(&:itself)
                                    .transform_values(&:count)
                                    .sort_by { |status, _| status.to_i }
                                    .to_h

      status_counts.each do |status, count|
        color = case status.to_i
        when 200..299 then "\e[32m" # green
        when 400..499 then "\e[33m" # yellow
        when 500..599 then "\e[31m" # red
        else "\e[0m"
        end
        puts "    #{color}#{status}: #{count}\e[0m"
      end
    end
  end

  def print_recent_requests(stats)
    puts "\nRecent Requests:"
    stats[:requests].to_a.last(5).each do |_, req|
      status_color = case req[:status]
      when 200..299 then "\e[32m" # green
      when 400..499 then "\e[33m" # yellow
      when 500..599 then "\e[31m" # red
      else "\e[0m"
      end
      puts "  #{status_color}#{req[:method]} #{req[:path]} - #{req[:status]} (#{req[:duration]}ms)\e[0m"
    end
  end

  def print_recent_errors(stats)
    return unless stats[:errors].any?

    puts "\nRecent Errors:"
    stats[:errors].last(3).each do |error|
      puts "  \e[31m[#{error['timestamp']}] #{error['message']}\e[0m"
    end
  end

  def analyze_log_content(content)
    stats = initialize_stats

    content.each_line do |line|
      # Skip empty lines and asset requests
      next if line.strip.empty?
      next if line.include?("/assets/") || line.include?("/packs/")

      puts "Processing line: #{line}" if ENV["DEBUG"]

      begin
        # Try parsing as JSON first
        entry = JSON.parse(line)
        process_entry(entry, stats)
      rescue JSON::ParserError
        # Handle Rails standard log format
        case line
        when /Started (\w+) "([^"]+)"/
          puts "Found request: #{line}" if ENV["DEBUG"]
          process_rails_log_entry(line, stats)
        when /Completed (\d+)/
          puts "Found completion: #{line}" if ENV["DEBUG"]
          process_rails_completion(line, stats)
        end
      end
    end

    print_analysis_results(stats)
  end

  def print_analysis_results(stats)
    # Print final analysis
    puts "\nLog Analysis Results:"
    print_summary(stats)

    if stats[:requests].any?
      puts "\nTop 5 Slowest Requests:"
      stats[:requests]
        .sort_by { |_, r| -(r[:duration] || 0) }
        .first(5)
        .each do |_, req|
          next unless req[:duration] # Skip requests without duration
          status_color = case req[:status]
          when 200..299 then "\e[32m" # green
          when 400..499 then "\e[33m" # yellow
          when 500..599 then "\e[31m" # red
          else "\e[0m"
          end
          puts "  #{status_color}#{req[:method]} #{req[:path]} - #{req[:status]} (#{req[:duration]}ms)\e[0m"
        end

      # Print path statistics
      puts "\nPath Statistics:"
      path_stats = stats[:requests]
        .group_by { |_, r| r[:path] }
        .transform_values do |reqs|
          completed_reqs = reqs.select { |_, r| r[:duration] }
          durations = completed_reqs.map { |_, r| r[:duration] }
          {
            count: reqs.size,
            completed: completed_reqs.size,
            avg_duration: durations.empty? ? 0 : durations.sum / durations.size,
            error_count: reqs.count { |_, r| r[:status].to_i >= 400 }
          }
        end

      path_stats.sort_by { |_, v| -v[:count] }.first(10).each do |path, stat|
        puts "  #{path}:"
        puts "    Total Requests: #{stat[:count]}"
        puts "    Completed: #{stat[:completed]}"
        puts "    Avg Duration: #{stat[:avg_duration].round(2)}ms"
        puts "    Errors: #{stat[:error_count]}"
      end
    end

    if stats[:errors].any?
      puts "\nAll Errors:"
      stats[:errors].each do |error|
        puts "  \e[31m[#{error['timestamp']}] #{error['message']}\e[0m"
      end
    end
  end
end
