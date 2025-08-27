module Ai
  class LlmSummaryService < BaseService
    include LlmServiceBase
    include Persistable

    def initialize(client_type = :gemini, config = {})
      @client = client_for(client_type, config)
      @client_type = client_type
    end

    class << self
      def fetch_summary(video_id, reset_on_failed: false)
        result = read_stored(video_id)
        if reset_on_failed && result&.dig(:success) == false
          delete_stored(video_id)
          return nil
        end
        result
      end
    end

    def process_task(video_id, transcript, metadata)
      log_info "Processing summary for video #{video_id}"
      return { success: false, error: "Video is too short" } if transcript.length < 100

      # Build messages using common method
      user_content = "Please summarize this video transcript: #{transcript} with the following metadata: #{metadata}"
      messages = build_system_user_messages(:summary_system_prompt, user_content)

      # Process using common method
      process_llm_task(messages, video_id, "summary_generation")
    end

    private

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
