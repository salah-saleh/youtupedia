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
  queue_as :default

  def perform(video_id)
    log_info "Starting summary job for video #{video_id}"
    # First get metadata (required for the UI and LLM prompt)
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    return unless metadata[:success]

    # Then get transcript (Python call). If it fails, cache the failure and still update the UI.
    log_info "Getting transcript for video #{video_id}"
    transcript = Youtube::YoutubeVideoTranscriptService.new.process_task(video_id)
    unless transcript[:success]
      log_error "Failed to get transcript", context: { video_id: video_id, error: transcript[:error] }
      transcript[:error] = "Failed to summarize video. Please try again later."
      Youtube::YoutubeVideoTranscriptService.write_cached(video_id, transcript, expires_in: nil)
      update_sections(video_id)
      return
    end

    # Cache the transcript result atomically
    Youtube::YoutubeVideoTranscriptService.write_cached(video_id, transcript, expires_in: nil)

    log_info "Transcript fetched for video #{video_id}"
    # Finally generate summary
    result = Ai::LlmSummaryService.new(:gemini).process_task(video_id, transcript[:transcript_full], metadata)

    # Cache the summary result atomically
    Ai::LlmSummaryService.write_cached(video_id, result, expires_in: nil)
    # Broadcast turbo streams to update sections
    update_sections(video_id)
    log_info "Summary job completed for video #{video_id}"
  end

  private
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
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    summary = transcript&.dig(:success) ? Ai::LlmSummaryService.fetch_summary(video_id) : nil
    SummariesController.new.send(:build_summary_data, video_id, metadata, transcript, summary)
  end
end
