# Handles fetching transcript and generating summary for a video
class SummaryJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    # First get metadata
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    return unless metadata[:success]

    # Then get transcript
    transcript = Youtube::YoutubeVideoTranscriptService.new.process_task(video_id)

    # Cache the transcript result atomically
    Youtube::YoutubeVideoTranscriptService.write_cached(video_id, transcript, expires_in: nil)
    return transcript unless transcript[:success]

    # Finally generate summary
    result = Ai::ChatGptService.new.process_task(video_id, transcript[:transcript_full], metadata)

    # Cache the summary result atomically
    Ai::ChatGptService.write_cached(video_id, result, expires_in: nil)
  end
end
