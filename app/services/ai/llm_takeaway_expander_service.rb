# frozen_string_literal: true

module Ai
  class LlmTakeawayExpanderService < BaseService
    include LlmServiceBase

    def initialize(client_type = :gemini)
      @client = client_for(client_type)
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
      # Get appropriate prompt based on client type
      prompt = get_prompt(@client_type, :takeaway_expansion_prompt)
      messages = build_messages(prompt, transcript, topic, takeaway)

      # Pass video_id and operation_type for tracking
      if @client_type == :gemini
        response = @client.chat(messages, video_id: video_id, operation_type: "takeaway_expansion")
      else
        response = @client.chat(messages)
      end
      
      handle_llm_response(response)
    end

    private

    def build_messages(prompt, transcript, topic, takeaway)
      [
        { role: "system", content: prompt },
        { role: "user", content: "Please expand on this takeaway about '#{topic}' from the video transcript: #{takeaway}. Here's the full transcript for context: #{transcript}" }
      ]
    end

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