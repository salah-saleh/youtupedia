module Ai
  module Clients
    class GeminiClient < BaseClient
      include PythonScriptable

      def chat(messages, video_id: nil, operation_type: nil)
        # Get the system prompt content
        system_prompt = messages.find { |m| m[:role] == "system" }&.fetch(:content, "")

        # Determine which script to use based on the system prompt content
        script_name = if system_prompt.include?("expanding and providing detailed explanations")
          "gemini_expanded_takeaway_client.py"
        else
          "gemini_summary_client.py"
        end

        # Convert Ruby symbols to strings for JSON serialization
        formatted_messages = messages.map do |msg|
          {
            "role" => msg[:role],
            "content" => msg[:content]
          }
        end

        # Prepare input data with additional context for logging
        input_data = {
          "messages" => formatted_messages,
          "video_id" => video_id,
          "operation_type" => operation_type
        }

        # Log the API call details before execution
        log_api_call_start(script_name, input_data, system_prompt)

        # Use a shorter timeout specifically for Gemini to prevent hanging
        gemini_timeout = ENV.fetch("GEMINI_TIMEOUT", 40).to_i
        start_time = Time.current
        
        result = run_python_script(script_name, input_data, timeout: gemini_timeout)
        
        # Log the API call results with token consumption and timing
        log_api_call_result(result, start_time, video_id, operation_type, script_name)

        if result[:success]
          { success: true, content: result[:content] }
        else
          { success: false, error: result[:error] }
        end
      end

      private

      def log_api_call_start(script_name, input_data, system_prompt)
        # Calculate input token estimates (rough approximation)
        input_tokens = estimate_input_tokens(input_data, system_prompt)
        
        log_info "Gemini API call starting", context: {
          script_name: script_name,
          video_id: input_data["video_id"],
          operation_type: input_data["operation_type"],
          model: "gemini-2.0-flash",
          estimated_input_tokens: input_tokens,
          generation_config: {
            temperature: 1,
            top_p: 0.95,
            top_k: 40,
            max_output_tokens: 20000,
            response_format: "json_object"
          },
          system_prompt_length: system_prompt.length,
          user_content_length: input_data["messages"].find { |m| m["role"] == "user" }&.dig("content")&.length || 0
        }
      end

      def log_api_call_result(result, start_time, video_id, operation_type, script_name)
        elapsed_time = Time.current - start_time
        
        if result[:success]
          # Extract token usage information if available
          token_info = extract_token_info(result)
          
          log_info "Gemini API call completed successfully", context: {
            script_name: script_name,
            video_id: video_id,
            operation_type: operation_type,
            model: "gemini-2.0-flash",
            elapsed_seconds: elapsed_time.round(3),
            success: true,
            **token_info
          }
        else
          log_error "Gemini API call failed", context: {
            script_name: script_name,
            video_id: video_id,
            operation_type: operation_type,
            model: "gemini-2.0-flash",
            elapsed_seconds: elapsed_time.round(3),
            success: false,
            error: result[:error]
          }
        end
      end

      def estimate_input_tokens(input_data, system_prompt)
        # Rough token estimation: 1 token ≈ 4 characters for English text
        # This is a simplified approximation - actual tokenization may vary
        total_chars = system_prompt.length
        
        input_data["messages"].each do |msg|
          total_chars += msg["content"].length
        end
        
        (total_chars / 4.0).round
      end

      def extract_token_info(result)
        # Try to extract token information from the result
        # The Python scripts will need to be updated to include this information
        if result[:token_usage]
          {
            input_tokens: result[:token_usage][:input_tokens],
            output_tokens: result[:token_usage][:output_tokens],
            total_tokens: result[:token_usage][:total_tokens]
          }
        elsif result[:usage]
          # Alternative key format
          {
            input_tokens: result[:usage][:input_tokens],
            output_tokens: result[:usage][:output_tokens],
            total_tokens: result[:usage][:total_tokens]
          }
        else
          # No token information available
          {
            input_tokens: nil,
            output_tokens: nil,
            total_tokens: nil
          }
        end
      end
    end
  end
end
