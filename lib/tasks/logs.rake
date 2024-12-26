# Log Analysis Tasks
#
# This file provides rake tasks for real-time log watching and analysis.
# The analysis works with the standard Rails log format, parsing request IDs,
# session IDs, and other context from the log lines.
#
# Available Tasks:
# - rake logs:watch   - Watch and analyze logs in real-time
# - rake logs:analyze - Analyze logs from a file
#
# Environment Variables:
# - DEBUG: Enable debug output
# - LOG_FILE: Specify alternative log file
namespace :logs do
  desc "Watch and analyze logs in real-time"
  task :watch do
    watch_development_logs
  end

  desc "Analyze logs from a file"
  task :analyze do
    analyze_development_logs
  end

  desc "Extract logs for a specific request ID"
  task :request do
    request_id = ENV["REQUEST_ID"]
    if request_id.nil? || request_id.empty?
      puts "Please provide a REQUEST_ID environment variable"
      puts "Example: rake logs:request REQUEST_ID=abc-123"
      exit 1
    end

    extract_request_logs(request_id)
  end

  private

  def watch_development_logs
    stats = initialize_stats
    puts "Watching development logs..."

    begin
      File.open("log/development.log", "r") do |log|
        log.seek(0, IO::SEEK_END)
        loop do
          process_new_logs(log, stats)
          display_stats(stats)
          sleep 0.1
        end
      end
    rescue Interrupt
      puts "\nFinal Statistics:"
      display_stats(stats)
    end
  end

  def analyze_development_logs
    puts "Analyzing development logs..."
    log_file = ENV["LOG_FILE"] || "log/development.log"
    stats = initialize_stats

    File.open(log_file, "r").each_line do |line|
      process_log_line(line, stats)
    end

    puts "\nAnalysis Results:"
    display_stats(stats)
  end

  def initialize_stats
    {
      requests: {},
      pending_requests: {},
      errors: [],
      response_times: [],
      start_time: Time.now,
      requests_by_controller: Hash.new(0),
      avg_response_times: Hash.new { |h, k| h[k] = [] }
    }
  end

  def process_new_logs(log, stats)
    while line = log.gets
      process_log_line(line, stats)
    end
  end

  def process_log_line(line, stats)
    puts "\nProcessing line: #{line}" if ENV["DEBUG"]

    # Extract request_id if present
    request_id = extract_request_id(line)
    puts "  Found request_id: #{request_id}" if ENV["DEBUG"] && request_id

    case line
    when /Started (\w+) "([^"]+)" for/
      method, path = $1, $2
      puts "  Matched START: method=#{method}, path=#{path}" if ENV["DEBUG"]
      process_request_start(method, path, stats)
    when /Processing by (\w+)#(\w+) as (\w+)/
      controller, action, format = $1, $2, $3
      puts "  Matched PROCESSING: controller=#{controller}, action=#{action}" if ENV["DEBUG"]
      process_controller_action(request_id, controller, action, format, stats)
    when /\[(\w+)Controller\].*Request (started|completed).*\{(.+)\}/
      controller, event, json_str = $1, $2, $3
      begin
        # Parse the JSON-like string into a hash
        data = json_str.split(",").map { |pair|
          k, v = pair.split(":").map(&:strip)
          [ k.delete('"{}'), v.to_s.delete('"{}') ]
        }.to_h

        if event == "completed"
          puts "  Matched CUSTOM COMPLETION: controller=#{controller}, duration=#{data['duration_ms']}, status=#{data['status']}" if ENV["DEBUG"]
          process_request_completion(request_id, data["status"], data["duration_ms"], stats)
        end
      rescue => e
        puts "  Error parsing JSON-like string: #{e.message}" if ENV["DEBUG"]
      end
    when /ERROR/
      puts "  Matched ERROR" if ENV["DEBUG"]
      stats[:errors] << line
    else
      puts "  No match for line" if ENV["DEBUG"]
    end
  end

  def extract_request_id(line)
    if line =~ /rid=([^\s\]]+)/
      $1
    end
  end

  def process_request_start(method, path, stats)
    return if path.start_with?("/assets/", "/packs/")

    # Create a unique key for this request based on method and path
    request_key = "#{method}:#{path}"
    puts "  Starting request with key: #{request_key}" if ENV["DEBUG"]

    # Create a new pending request
    stats[:pending_requests][request_key] = {
      path: path,
      method: method,
      start_time: Time.now,
      controller: nil,
      action: nil,
      status: nil,
      duration: nil,
      request_id: nil
    }
  end

  def process_controller_action(request_id, controller, action, format, stats)
    request = find_request(request_id, controller, stats)
    return unless request

    puts "  Setting controller/action: #{controller}##{action}" if ENV["DEBUG"]
    request[:controller] = controller
    request[:action] = action
    request[:format] = format
    request[:request_id] = request_id if request_id

    key = "#{controller}##{action}"
    stats[:requests_by_controller][key] += 1
    stats[:avg_response_times][key] ||= []
  end

  def process_request_completion(request_id, status, duration, stats)
    request = find_request(request_id, nil, stats)
    return unless request

    # Skip if this request has already been completed
    return if request[:status]

    puts "  Completing request with status: #{status}, duration: #{duration}" if ENV["DEBUG"]
    request[:status] = status.to_i
    request[:duration] = duration.to_f

    if request[:controller] && request[:action]
      key = "#{request[:controller]}##{request[:action]}"
      stats[:avg_response_times][key] << duration.to_f
      puts "  Updated avg_response_times for #{key}: #{stats[:avg_response_times][key]}" if ENV["DEBUG"]
    end

    stats[:response_times] << duration.to_f
    puts "  Updated response_times: #{stats[:response_times]}" if ENV["DEBUG"]

    # Move from pending to completed
    if request_id
      key = stats[:pending_requests].keys.find { |k| stats[:pending_requests][k] == request }
      if key
        stats[:requests][request_id] = stats[:pending_requests].delete(key)
      end
    else
      # Try to find by method/path if no request_id
      key = stats[:pending_requests].keys.find { |k| stats[:pending_requests][k] == request }
      if key
        stats[:requests][key] = stats[:pending_requests].delete(key)
      end
    end
  end

  def find_request(request_id, controller, stats)
    if request_id
      # First try to find by request_id in pending requests
      request = stats[:pending_requests].values.find { |r| r[:request_id] == request_id }
      return request if request

      # Then try completed requests
      request = stats[:requests][request_id]
      return request if request
    end

    # If no request_id or not found by request_id, try to find by controller
    if controller
      stats[:pending_requests].values.find do |req|
        !req[:controller] || req[:controller] == controller
      end
    else
      # If no controller specified, return the oldest pending request
      stats[:pending_requests].values.first
    end
  end

  def display_stats(stats)
    # Only clear the screen if we're not in debug mode
    system("clear") || system("cls") unless ENV["DEBUG"]

    puts "\n----------------------------------------"
    puts "Log Analysis Statistics"
    puts "======================"
    puts
    puts "Total Requests: #{stats[:requests].size}"
    puts "Pending Requests: #{stats[:pending_requests].size}"
    puts "Error Count: #{stats[:errors].size}"

    if stats[:response_times].any?
      avg_time = stats[:response_times].sum / stats[:response_times].size
      puts "Average Response Time: #{avg_time.round(2)}ms"
      puts "Response Time Range: #{stats[:response_times].min.round(2)}ms - #{stats[:response_times].max.round(2)}ms"
    end

    puts "\nTop Controllers:"
    stats[:requests_by_controller].sort_by { |_, v| -v }.first(5).each do |controller, count|
      avg_time = stats[:avg_response_times][controller].sum / stats[:avg_response_times][controller].size rescue 0
      min_time = stats[:avg_response_times][controller].min rescue 0
      max_time = stats[:avg_response_times][controller].max rescue 0
      puts "  #{controller}: #{count} requests (avg: #{avg_time.round(2)}ms, range: #{min_time.round(2)}ms - #{max_time.round(2)}ms)"
    end

    if stats[:errors].any?
      puts "\nRecent Errors:"
      stats[:errors].last(3).each do |error|
        puts "  #{error.strip}"
      end
    end

    puts "\nRecent Requests:"
    completed_requests = stats[:requests].values.select { |r| r[:status] }.sort_by { |r| r[:start_time] }.last(5)
    completed_requests.each do |req|
      status_color = req[:status] == 200 ? "\e[32m" : "\e[31m"
      duration_str = req[:duration] ? "(#{req[:duration].round(2)}ms)" : ""
      controller_action = req[:controller] && req[:action] ? " [#{req[:controller]}##{req[:action]}]" : ""
      puts "  #{req[:method]} #{req[:path]}#{controller_action} - #{status_color}#{req[:status]}\e[0m #{duration_str}"
    end

    if stats[:pending_requests].any?
      puts "\nPending Requests:"
      stats[:pending_requests].each do |key, req|
        elapsed = ((Time.now - req[:start_time]) * 1000).round(2)
        controller_action = req[:controller] && req[:action] ? " [#{req[:controller]}##{req[:action]}]" : ""
        puts "  #{req[:method]} #{req[:path]}#{controller_action} (#{elapsed}ms elapsed)"
      end
    end
    puts "----------------------------------------\n"
  end

  def extract_request_logs(request_id)
    puts "Extracting logs for request ID: #{request_id}"
    puts "----------------------------------------\n"

    log_file = ENV["LOG_FILE"] || "log/development.log"
    found_lines = []

    File.open(log_file, "r").each_line do |line|
      if line.include?(request_id)
        found_lines << line.strip
      end
    end

    if found_lines.empty?
      puts "No logs found for request ID: #{request_id}"
      return
    end

    # Group logs by severity
    severity_groups = {
      "DEBUG" => [],
      "INFO" => [],
      "WARN" => [],
      "ERROR" => [],
      "FATAL" => []
    }

    found_lines.each do |line|
      severity = line.split(" | ")[1]&.strip || "INFO"
      severity_groups[severity] ||= []
      severity_groups[severity] << line
    end

    # Print summary
    total_lines = found_lines.size
    puts "Found #{total_lines} log entries\n\n"
    severity_groups.each do |severity, lines|
      next if lines.empty?
      percentage = ((lines.size.to_f / total_lines) * 100).round(1)
      puts "#{severity}: #{lines.size} lines (#{percentage}%)"
    end
    puts "\n----------------------------------------\n"

    # Print logs grouped by severity
    severity_groups.each do |severity, lines|
      next if lines.empty?
      puts "\n#{severity} Logs:"
      puts "============\n"
      lines.each do |line|
        # Extract timestamp and message
        parts = line.split(" | ")
        timestamp = parts[0]
        message = parts[2..-1]&.join(" | ")

        # Format the output
        puts "#{timestamp.strip}"
        puts "  #{message.strip}"
      end
    end
    puts "\n----------------------------------------"
  end
end
