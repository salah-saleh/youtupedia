# Handles fetching transcript and generating summary for a video.
#
# Responsibilities:
# 1) Ensure YouTube metadata exists (idempotent read via cache service)
# 2) Build or reuse the transcript (delegates to Python via YoutubeVideoTranscriptService)
# 3) Generate the summary (delegates to LlmSummaryService)
# 4) Cache results atomically (both transcript and summary)
# 5) Push UI updates via Turbo Streams over ActionCable to the stream key
#    "summaries:#{video_id}" (see view: turbo_stream_from)
#
# The job is safe to schedule multiple times; each step is idempotent through caching.
class SummaryJob < ApplicationJob
  include JobSchedulable
  
  queue_as :default

  def perform(video_id)
    log_info "Starting summary job for video #{video_id}"
    
    # First get metadata (required for the UI and LLM prompt)
    # Add timeout protection for metadata fetching
    metadata = fetch_metadata_with_timeout(video_id)
    return unless metadata[:success]

    # Then get transcript (Python call). If it fails, cache the failure and still update the UI.
    log_info "Getting transcript for video #{video_id}"
    transcript = Youtube::YoutubeVideoTranscriptService.new.process_task(video_id)
    unless transcript[:success]
      log_error "Failed to get transcript", context: { video_id: video_id, error: transcript[:error] }
      transcript[:error] = "Failed to summarize video. Please try again later."
      Youtube::YoutubeVideoTranscriptService.write_stored(video_id, transcript)
      update_sections(video_id)
      return
    end

    # Store the transcript result atomically
    Youtube::YoutubeVideoTranscriptService.write_stored(video_id, transcript)

    log_info "Transcript fetched for video #{video_id}"
    # Finally generate summary
    result = Ai::LlmSummaryService.new(:gemini).process_task(video_id, transcript[:transcript_full], metadata)

    # Store the summary result atomically
    Ai::LlmSummaryService.write_stored(video_id, result)
    # Broadcast turbo streams to update sections
    update_sections(video_id)
    log_info "Summary job completed for video #{video_id}"
  end

  private

  # Add timeout protection for metadata fetching
  def fetch_metadata_with_timeout(video_id, timeout_seconds: 2)
    Timeout.timeout(timeout_seconds) do
      Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    end
  rescue Timeout::Error
    log_error "Metadata fetch timed out after #{timeout_seconds} seconds", context: { video_id: video_id }
    { success: false, error: "Failed to fetch video metadata within #{timeout_seconds} seconds" }
  rescue => e
    log_error "Metadata fetch failed", context: { video_id: video_id, error: e.message }
    { success: false, error: "Failed to fetch video metadata: #{e.message}" }
  end

  def update_sections(video_id)
    log_info "Updating sections for video #{video_id}"
    # Push server-rendered Turbo Streams directly to the stream identified in the view
    payload = build_summary_payload(video_id)
    %w[tldr transcript takeaways summary].each do |section|
      Turbo::StreamsChannel.broadcast_replace_to(
        "summaries:#{video_id}",
        target: section,
        partial: "summaries/show/#{section}_section",
        locals: { summary: payload }
      )
    end
  end

  def build_summary_payload(video_id)
    # Fetch all data in one go to avoid redundant storage calls
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    summary = transcript&.dig(:success) ? Ai::LlmSummaryService.fetch_summary(video_id) : nil
    
    # Build summary data using the fetched data
    SummariesController.new.send(:build_summary_data, video_id, metadata, transcript, summary)
  end
end