# Handles fetching transcript and generating summary for a video
class SummaryJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    # First get metadata
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    return unless metadata[:success]

    # Then get transcript
    transcript = Youtube::YoutubeVideoTranscriptService.new.process_task(video_id)
    unless transcript[:success]
      log_error "Failed to get transcript", context: { video_id: video_id, error: transcript[:error] }
      transcript[:error] = "Failed to summarize video. Please try again later."
    end

    # Cache the transcript result atomically
    Youtube::YoutubeVideoTranscriptService.write_cached(video_id, transcript, expires_in: nil)
    return transcript unless transcript[:success]

    # Finally generate summary
    result = Ai::LlmSummaryService.new(:gemini).process_task(video_id, transcript[:transcript_full], metadata)

    # Cache the summary result atomically
    Ai::LlmSummaryService.write_cached(video_id, result, namespace: "chat_gpt_services", expires_in: nil)
  end
end
