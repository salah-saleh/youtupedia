module Ai
  module Clients
    class GeminiClient < BaseClient
      include PythonScriptable

      def initialize(config = {})
        @config = default_config.merge(config)
      end

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

        # Prepare input data with additional context and configuration
        input_data = {
          "messages" => formatted_messages,
          "video_id" => video_id,
          "operation_type" => operation_type,
          "config" => @config
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

      def default_config
        {
          # Gemini model to use for API calls
          # - gemini-2.0-flash: Fast, efficient model (default)
          # - gemini-2.0-flash-exp: Experimental version with extended capabilities
          # - gemini-1.5-flash: Previous generation, still powerful
          "model_name" => ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash"),
          
          # Controls randomness and creativity in responses
          # - 0.0: Very predictable, consistent outputs (good for summaries)
          # - 1.0: Balanced creativity (default)
          # - 2.0: Maximum creativity, varied outputs (good for content generation)
          "temperature" => ENV.fetch("GEMINI_TEMPERATURE", 1.0).to_f,
          
          # Nucleus sampling - controls vocabulary diversity
          # - 0.1: Only considers top 10% of possible tokens (narrow vocabulary)
          # - 0.95: Considers top 95% of possible tokens (default, balanced)
          # - 1.0: Considers all possible tokens (maximum diversity)
          "top_p" => ENV.fetch("GEMINI_TOP_P", 0.95).to_f,
          
          # Limits the number of possible next tokens to consider
          # - 10: Only considers top 10 possibilities (highly predictable)
          # - 40: Considers top 40 possibilities (default, balanced)
          # - 100: Considers top 100 possibilities (maximum variety)
          "top_k" => ENV.fetch("GEMINI_TOP_K", 40).to_i,
          
          # Maximum number of tokens the AI can generate in response
          # - 5000: Short responses (good for quick answers)
          # - 20000: Medium responses (default, good for summaries)
          # - 50000: Long responses (good for detailed content)
          "max_output_tokens" => ENV.fetch("GEMINI_MAX_OUTPUT_TOKENS", 20000).to_i,
          # Response format - always JSON for structured output
          "response_mime_type" => "application/json"
        }
      end

      def log_api_call_start(script_name, input_data, system_prompt)
        # Calculate input token estimates (rough approximation)
        input_tokens = estimate_input_tokens(input_data, system_prompt)
        
        log_info "Gemini API call starting", context: {
          script_name: script_name,
          video_id: input_data["video_id"],
          operation_type: input_data["operation_type"],
          model: @config["model_name"],
          estimated_input_tokens: input_tokens,
          generation_config: @config,
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
            model: @config["model_name"],
            elapsed_seconds: elapsed_time.round(3),
            success: true,
            **token_info
          }
        else
          log_error "Gemini API call failed", context: {
            script_name: script_name,
            video_id: video_id,
            operation_type: operation_type,
            model: @config["model_name"],
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
