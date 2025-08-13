# Home page controller that provides the landing page and public features.
# Dependencies:
# - ApplicationController (inherits base functionality)
# - Authentication module (for optional user context)
class HomeController < ApplicationController
  include SummaryDataHelper
  public_actions :index

  DEMO_VIDEO_ID = "BEWz4SXfyCQ"

  def index
    # Load demo summary data for the landing page without scheduling compute
    begin
      metadata   = Youtube::YoutubeVideoMetadataService.fetch_metadata(DEMO_VIDEO_ID)
      transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(DEMO_VIDEO_ID)
      summary    = Ai::LlmSummaryService.fetch_summary(DEMO_VIDEO_ID)
      @demo_summary_data = build_summary_data(DEMO_VIDEO_ID, metadata, transcript, summary)
    rescue => e
      Rails.logger.error("Failed to load demo summary: #{e.message}")
      @demo_summary_data = { video_id: DEMO_VIDEO_ID, title: "Example summary", loading: true, contents: [], tldr: "", summary: "", transcript_segmented: [], transcript_full: "" }
    end
  end
end
