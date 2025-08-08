module Ai
  class LlmSummaryService < BaseService
    include AsyncProcessable
    include Cacheable
    include LlmServiceBase

    def initialize(client_type = :gemini)
      @client = client_for(client_type)
      @client_type = client_type
    end

    class << self
      def fetch_summary(video_id)
        fetch_cached(video_id, expires_in: nil)
      end
    end

    def process_task(video_id, transcript, metadata)
      log_info "Processing summary for video #{video_id}"
      return { success: false, error: "Video is too short" } if transcript.length < 100

      # Get appropriate prompt based on client type
      prompt = get_prompt(@client_type, :summary_system_prompt)
      messages = build_messages(prompt, transcript, metadata)

      response = @client.chat(messages)
      handle_llm_response(response)
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

    def validate_response(result)
      unless result[:tldr] && result[:contents] && result[:summary]
        return { success: false, error: "Missing required fields in response" }
      end

      {
        success: true,
        tldr: result[:tldr],
        contents: result[:contents],
        summary: result[:summary]
      }
    end
  end
end
