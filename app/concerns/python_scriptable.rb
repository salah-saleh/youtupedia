# Provides functionality for safely executing Python scripts with proper resource management
#
# This concern implements several key techniques for managing memory and resources:
#
# 1. Process Lifecycle Management:
#    - Each Python process is properly terminated after execution
#    - Process trees are cleaned up to prevent zombie processes
#    - Resources are released even if errors occur
#
# 2. Memory Management:
#    - Explicit garbage collection after process completion
#    - Proper cleanup of file descriptors
#    - Stream handling for large inputs/outputs
#
# 3. Resource Protection:
#    - Timeout protection against hanging processes
#    - Process tree cleanup to prevent resource leaks
#    - Error handling with proper resource cleanup
#
# @example
#   class MyService
#     include PythonScriptable
#
#     def process_data(input)
#       result = run_python_script("my_script.py", input)
#       # Handle result...
#     end
#   end

require 'fcntl'

module PythonScriptable
  extend ActiveSupport::Concern

  # Constants are being redefined because the module is being included multiple times
  # Let's define them only if they're not already defined
  unless const_defined?(:SCRIPT_TIMEOUT)
    SCRIPT_TIMEOUT = ENV.fetch("PYTHON_SCRIPT_TIMEOUT", 30).to_i
  end

  unless const_defined?(:MAX_MEMORY_MB)
    MAX_MEMORY_MB = ENV.fetch("PYTHON_MAX_MEMORY_MB", 500).to_i
  end

  included do
    # Memory Management Configuration
    #
    # Dyno Size Reference & Recommended Settings:
    # Basic (512MB):
    #   MAX_MEMORY_PER_PROCESS=460MB (90% of total)
    #   MALLOC_ARENA_MAX=2
    #   MMAP_THRESHOLD=131072
    #
    # Standard-1X (1GB):
    #   MAX_MEMORY_PER_PROCESS=920MB
    #   MALLOC_ARENA_MAX=4
    #   MMAP_THRESHOLD=262144
    #
    # Standard-2X/Performance-M (2.5GB):
    #   MAX_MEMORY_PER_PROCESS=2300MB
    #   MALLOC_ARENA_MAX=8
    #   MMAP_THRESHOLD=524288
    #
    # Performance-L (14GB):
    #   MAX_MEMORY_PER_PROCESS=12800MB
    #   MALLOC_ARENA_MAX=16
    #   MMAP_THRESHOLD=1048576
  end

  class_methods do
    # Class method version of run_python_script
    def run_python_script(script_name, input_data, timeout: SCRIPT_TIMEOUT)
      new.run_python_script(script_name, input_data, timeout: timeout)
    end
  end

  # Executes a Python script with proper resource management
  #
  # @param script_name [String] Name of the Python script to execute
  # @param input_data [] Data to pass to the Python script
  # @param timeout [Integer] Timeout in seconds (defaults to SCRIPT_TIMEOUT)
  # @return [Hash] Result of script execution with success status
  def run_python_script(script_name, input_data, timeout: PythonScriptConfig.script_timeout)
    script_path = Rails.root.join("lib", "python", script_name)
    command = "#{PythonScriptConfig.python_path} #{script_path}"
    status = nil

    # Check memory before starting new process
    check_memory_usage

    begin
      Timeout.timeout(timeout) do
        log_info "Running Python script", context: {
          script_path: script_path,
          memory_mb: current_memory_mb
        }

        # Use popen3 with explicit resource limits and non-blocking I/O
        Open3.popen3(
          {
            "PYTHONPATH" => ENV["PYTHONPATH"],
            # MALLOC_ARENA_MAX: Limits the number of memory pools
            # - Lower = Less memory fragmentation but potentially slower
            # - Higher = Better performance but more memory usage
            # Formula: log2(MAX_MEMORY_MB/256), minimum 2
            "MALLOC_ARENA_MAX" => PythonScriptConfig.malloc_arena_max.to_s,
            # MMAP_THRESHOLD: Size threshold for using mmap
            # - Lower = Less memory fragmentation
            # - Higher = Better performance for large allocations
            # Formula: MAX_MEMORY_MB * 256, minimum 128KB
            "MMAP_THRESHOLD" => PythonScriptConfig.mmap_threshold.to_s
          },
          command
        ) do |stdin, stdout, stderr, wait_thread|
          # Store PID for cleanup
          status = wait_thread
          
          # Write input data and close stdin
          stdin.write(input_data.to_json)
          stdin.close

          # Use non-blocking I/O with timeout to prevent hanging
          output, error = read_with_timeout(stdout, stderr, timeout, wait_thread)

          # Get the exit status
          status = wait_thread.value

          # Check memory after process completion
          check_memory_usage

          if status.success?
            JSON.parse(output, symbolize_names: true)
          else
            log_error "Python script failed", context: {
              script_name: script_name,
              pid: wait_thread.pid,
              exit_code: status.exitstatus,
              stderr: error,
              stdout: output
            }
            {
              success: false,
              error: error.presence || "Python script failed with exit code #{status.exitstatus}"
            }
          end
        end
      end
    rescue Timeout::Error
      kill_process_tree(status&.pid)
      { success: false, error: "Python script timed out after #{timeout} seconds" }
    rescue MemoryLimitExceededError => e
      kill_process_tree(status&.pid)
      { success: false, error: "Memory limit exceeded: #{e.message}" }
    rescue => e
      { success: false, error: "Failed to run Python script: #{e.message}" }
    ensure
      if status&.pid
        kill_process_tree(status.pid)
        log_info "Cleaned up Python process", context: {
          pid: status.pid,
          memory_mb: current_memory_mb
        }
      end
      GC.start
    end
  end

  # Reads from stdout and stderr with timeout protection using IO.select
  #
  # This method prevents hanging on blocking read operations by using IO.select
  # to check if data is available before attempting to read.
  #
  # @param stdout [IO] Standard output stream
  # @param stderr [IO] Standard error stream  
  # @param timeout [Integer] Timeout in seconds
  # @param wait_thread [Thread] Process thread for cleanup
  # @return [Array<String, String>] Output and error strings
  def read_with_timeout(stdout, stderr, timeout, wait_thread)
    output = ""
    error = ""
    deadline = Time.now + timeout
    
    # Set streams to non-blocking mode
    stdout.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
    stderr.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)
    
    while Time.now < deadline
      # Use IO.select to check if data is available within remaining time
      remaining_time = deadline - Time.now
      break if remaining_time <= 0
      
      # Check if process has finished
      unless wait_thread.alive?
        # Process finished, read any remaining output
        begin
          output += stdout.read_nonblock(65536) while stdout.ready?
        rescue EOFError, Errno::EAGAIN, Errno::EWOULDBLOCK
          # No more data available
        end
        
        begin
          error += stderr.read_nonblock(65536) while stderr.ready?
        rescue EOFError, Errno::EAGAIN, Errno::EWOULDBLOCK
          # No more data available
        end
        break
      end
      
      # Wait for data to be available on either stream
      ready = IO.select([stdout, stderr], nil, nil, [remaining_time, 0.1].min)
      
      if ready
        ready[0].each do |stream|
          begin
            if stream == stdout
              output += stream.read_nonblock(65536)
            elsif stream == stderr
              error += stream.read_nonblock(65536)
            end
          rescue EOFError
            # Stream closed, continue
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            # No data available right now, continue
          end
        end
      end
      
      # Small sleep to prevent busy waiting
      sleep(0.01)
    end
    
    # If we reach here and process is still alive, it timed out
    if wait_thread.alive?
      kill_process_tree(wait_thread.pid)
      raise Timeout::Error, "Process timed out and was terminated"
    end
    
    [output, error]
  rescue => e
    # Ensure process is killed on any error
    kill_process_tree(wait_thread.pid) if wait_thread&.alive?
    raise e
  end

  # Safely terminates a process and all its children
  #
  # @param pid [Integer] Process ID to terminate
  # @return [void]
  def kill_process_tree(pid)
    return unless pid
    begin
      # Send TERM signal to the process group
      Process.kill("-TERM", Process.getpgid(pid))
      sleep(0.1)  # Give process time to terminate gracefully
      
      # If process is still running, send KILL signal
      if process_exists?(pid)
        Process.kill("-KILL", Process.getpgid(pid))
      end
    rescue Errno::ESRCH, Errno::EPERM
      # Process already terminated or permission denied
      nil
    end
  end
  
  # Check if a process exists
  #
  # @param pid [Integer] Process ID to check
  # @return [Boolean] True if process exists
  def process_exists?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true  # Process exists but we don't have permission to signal it
  end

  private

  def check_memory_usage
    memory_mb = current_memory_mb
    if memory_mb > PythonScriptConfig.max_memory_mb
      log_error "Memory limit exceeded", context: { memory_mb: memory_mb }
      raise MemoryLimitExceededError, 
        "Process using #{memory_mb}MB exceeds limit of #{PythonScriptConfig.max_memory_mb}MB"
    end
  end

  def current_memory_mb
    (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round(2)
  end

  class MemoryLimitExceededError < StandardError; end
end
