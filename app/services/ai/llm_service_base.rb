module Ai
  module LlmServiceBase
    def client_for(client_type)
      case client_type
      when :openai
        Clients::OpenaiClient.new
      when :gemini
        Clients::GeminiClient.new
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