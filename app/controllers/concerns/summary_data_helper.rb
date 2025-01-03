module SummaryDataHelper
  extend ActiveSupport::Concern

  private

  def build_summary_data(video_id, metadata, transcript, summary)
    base_data = {
      video_id: video_id,
      title: metadata.dig(:metadata, :title),
      channel: metadata.dig(:metadata, :channel_title),
      date: metadata.dig(:metadata, :published_at)&.strftime("%B %d, %Y"),
      thumbnail: metadata.dig(:metadata, :thumbnails, :high),
      description: metadata.dig(:metadata, :description)
    }


    # If we have data but there was an error
    if transcript&.dig(:error) || summary&.dig(:error)
      return base_data.merge(
        loading: false,
        error: transcript&.dig(:error) || summary&.dig(:error),
        transcript_segmented: transcript&.dig(:transcript_segmented) || [],
        transcript_full: transcript&.dig(:transcript_full) || "",
        tldr: transcript&.dig(:error)&.first(300) || summary&.dig(:error)&.first(300) || "Unknown error",
        contents: [],
        summary: ""
      )
    end

    # If we have no data yet, everything is loading
    if !transcript || !summary
      return base_data.merge(
        loading: true,
        transcript_segmented: [],
        transcript_full: "",
        tldr: "",
        contents: [],
        summary: ""
      )
    end

    # If we have successful data
    base_data.merge(
      loading: false,
      transcript_segmented: transcript&.dig(:transcript_segmented) || [],
      transcript_full: transcript&.dig(:transcript_full) || "",
      tldr: summary&.dig(:tldr) || "",
      contents: summary&.dig(:contents) || [],
      summary: summary&.dig(:summary) || ""
    )
  end
end
