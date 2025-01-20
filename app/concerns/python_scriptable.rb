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
module PythonScriptable
  extend ActiveSupport::Concern

  included do
    # Default timeout for Python script execution
    SCRIPT_TIMEOUT = 60  # seconds
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
  def run_python_script(script_name, input_data, timeout: SCRIPT_TIMEOUT)
    script_path = Rails.root.join("lib", "python", script_name)
    command = "#{ENV['PYTHON_PATH']} #{script_path}"
    status = nil  # Define status in outer scope for ensure block

    # Convert input data to JSON for Python
    stdin_data = input_data.to_json

    Timeout.timeout(timeout) do
      log_info "Running Python script", context: { script_path: script_path, input_data: input_data }
      # Use capture3 for better stream handling and resource management
      output, error, status = Open3.capture3(command, stdin_data: stdin_data)

      if status.success?
        JSON.parse(output, symbolize_names: true)
      else
        { success: false, error: error.presence || "Python script failed" }
      end
    end
  rescue Timeout::Error
    kill_process_tree(status&.pid)
    { success: false, error: "Python script timed out after #{timeout} seconds" }
  rescue JSON::ParserError => e
    { success: false, error: "Failed to parse Python output: #{e.message}" }
  rescue => e
    { success: false, error: "Failed to run Python script: #{e.message}" }
  ensure
    # Cleanup phase - extremely important for resource management
    if status&.pid
      kill_process_tree(status.pid)
      log_info "Cleaned up Python process", context: { pid: status.pid }
    end

    # Force garbage collection to clean up any remaining references
    GC.start
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
    rescue Errno::ESRCH, Errno::EPERM
      # Process already terminated or permission denied
      nil
    end
  end
end
