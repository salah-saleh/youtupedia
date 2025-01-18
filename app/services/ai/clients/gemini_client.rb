module Ai
  module Clients
    class GeminiClient < BaseClient
      def chat(messages)
        # TODO: provide a better generic way to interface with python scripts
        script_name = "gemini_summary_client.py"

        # Pass messages directly without wrapping
        result = run_python_script(script_name, messages)

        if result[:success]
          { success: true, content: result[:content] }
        else
          { success: false, error: result[:error] }
        end
      end

      private

      def run_python_script(script_name, input_data)
        script_path = Rails.root.join("lib", "python", script_name)
        command = "#{ENV['PYTHON_PATH']} #{script_path}"

        # Use Open3.capture3 which is more efficient and thread-safe
        stdin_data = input_data.to_json
        output, error, status = Open3.capture3(command, stdin_data: stdin_data)

        if status.success?
          JSON.parse(output, symbolize_names: true)
        else
          { success: false, error: error.presence || "Python script failed" }
        end
      rescue JSON::ParserError => e
        { success: false, error: "Failed to parse Python output: #{e.message}" }
      rescue => e
        { success: false, error: "Failed to run Python script: #{e.message}" }
      end
    end
  end
end
