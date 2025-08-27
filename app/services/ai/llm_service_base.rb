module Ai
  module LlmServiceBase
    def client_for(client_type, config = {})
      case client_type
      when :openai
        Clients::OpenaiClient.new
      when :gemini
        Clients::GeminiClient.new(config)
      else
        raise ArgumentError, "Unknown client type: #{client_type}"
      end
    end

    def get_prompt(client_type, prompt_type)
      case client_type
      when :openai
        Ai::Prompts::PromptStore.send("#{prompt_type}_openai")
      when :gemini
        Ai::Prompts::PromptStore.send("#{prompt_type}_gemini")
      end
    end

    def handle_llm_response(response)
      return { success: false, error: response[:error] } unless response[:success]
      
      parse_response(response[:content])
    rescue JSON::ParserError => e
      log_error "JSON parsing error", context: { error: e.message, content: response[:content] }
      { success: false, error: "Failed to parse response: #{e.message}" }
    end

    # Common method to process LLM tasks with tracking
    def process_llm_task(messages, video_id, operation_type, client_type = @client_type)
      # Pass video_id and operation_type for tracking if using Gemini
      if client_type == :gemini
        response = @client.chat(messages, video_id: video_id, operation_type: operation_type)
      else
        response = @client.chat(messages)
      end
      
      handle_llm_response(response)
    end

    # Common method to build system + user messages
    def build_system_user_messages(prompt_type, user_content, client_type = @client_type)
      prompt = get_prompt(client_type, prompt_type)
      [
        { role: "system", content: prompt },
        { role: "user", content: user_content }
      ]
    end

    # Common method to build messages with custom prompt and content
    def build_custom_messages(system_prompt, user_content)
      [
        { role: "system", content: system_prompt },
        { role: "user", content: user_content }
      ]
    end

    private

    def parse_response(content)
      result = JSON.parse(content, symbolize_names: true)
      validate_response(result)
    end

    def validate_response(result)
      raise NotImplementedError, "Subclasses must implement validate_response"
    end
  end
end 