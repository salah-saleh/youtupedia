module Ai
  class LlmSummaryService < BaseService
    include AsyncProcessable
    include Cacheable

    def initialize(client_type = :openai)
      @client = client_for(client_type)
      @client_type = client_type
    end

    class << self
      def fetch_summary(video_id)
        fetch_cached(video_id, namespace: "chat_gpt_services", expires_in: nil)
      end
    end

    def process_task(video_id, transcript, metadata)
      return { success: false, error: "Video is too short" } if transcript.length < 100

      # Get appropriate prompt based on client type
      prompt = case @client_type
      when :openai
        Prompts::PromptStore.summary_system_prompt_openai
      when :gemini
        Prompts::PromptStore.summary_system_prompt_gemini
      end

      messages = build_messages(prompt, transcript, metadata)

      response = @client.chat(
        messages: messages
      )
      return { success: false, error: response[:error] } unless response[:success]

      parse_summary_response(response[:content])
    end

    private

    def build_messages(prompt, transcript, metadata)
      [
        { role: "system", content: prompt },
        { role: "user", content: "Please summarize this video transcript: #{transcript} with the following metadata: #{metadata}" }
      ]
    end

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

    def parse_summary_response(content)
      result = JSON.parse(content, symbolize_names: true)

      unless result[:tldr] && result[:contents] && result[:summary]
        return { success: false, error: "Missing required fields in response" }
      end

      {
        success: true,
        tldr: result[:tldr],
        contents: result[:contents],
        summary: result[:summary]
      }
    rescue JSON::ParserError => e
      log_error "JSON parsing error", context: { error: e.message, content: content }
      { success: false, error: "Failed to parse summary: #{e.message}" }
    end
  end
end
