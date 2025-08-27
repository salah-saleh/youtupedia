# frozen_string_literal: true

module Ai
  class LlmTakeawayExpanderService < BaseService
    include LlmServiceBase

    def initialize(client_type = :gemini, config = {})
      @client = client_for(client_type, config)
      @client_type = client_type
    end

    class << self
      def expand_takeaway(video_id, index, transcript, topic, takeaway)
        # Get the existing summary data
        summary_data = Ai::LlmSummaryService.fetch_summary(video_id)
        return { success: false, error: "Summary not found" } unless summary_data&.dig(:success)

        # if data is already expanded, return it
        if summary_data[:contents][index]&.dig(:expanded_takeaway)
          return { success: true, expanded_takeaway: summary_data[:contents][index][:expanded_takeaway] }
        end

        # Process the expansion
        expansion_result = new.process_expansion(transcript, topic, takeaway, video_id)
        return expansion_result unless expansion_result[:success]

        # Update the contents array with the expanded takeaway
        summary_data[:contents][index][:expanded_takeaway] = expansion_result[:expanded_takeaway]

        # Update the storage with the modified summary data
        Ai::LlmSummaryService.write_stored(video_id, summary_data)

        # Return just the expansion result for the turbo frame
        expansion_result
      end
    end

    def process_expansion(transcript, topic, takeaway, video_id)
      log_info "Processing takeaway expansion for video #{video_id}"
      # Build messages using common method
      user_content = "Please expand on this takeaway about '#{topic}' from the video transcript: #{takeaway}. Here's the full transcript for context: #{transcript}"
      messages = build_system_user_messages(:takeaway_expansion_prompt, user_content)

      # Process using common method
      process_llm_task(messages, video_id, "takeaway_expansion")
    end

    private

    def validate_response(result)
      unless result[:expanded_takeaway]
        return { success: false, error: "Missing required fields in response" }
      end

      {
        success: true,
        expanded_takeaway: result[:expanded_takeaway]
      }
    end
  end
end