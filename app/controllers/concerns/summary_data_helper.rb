module SummaryDataHelper
  extend ActiveSupport::Concern

  private

  def build_summary_data(video_id, metadata, transcript, result = nil)
    base_data = {
      video_id: video_id,
      title: metadata.dig(:metadata, :title),
      channel: metadata.dig(:metadata, :channel_title),
      date: metadata.dig(:metadata, :published_at),
      thumbnail: metadata.dig(:metadata, :thumbnails, :high),
      description: metadata.dig(:metadata, :description),
      transcript: transcript[:transcript_segmented]
    }

    if result
      if result[:success]
        base_data.merge(
          loading: false,
          tldr: result[:tldr],
          takeaways: result[:takeaways],
          tags: result[:tags],
          summary: result[:summary]
        )
      else
        base_data.merge(
          loading: false,
          tldr: result[:error],
          takeaways: [],
          tags: [],
          summary: ""
        )
      end
    else
      base_data.merge(
        loading: true,
        tldr: "",
        takeaways: [],
        tags: [],
        summary: ""
      )
    end
  end

  def fetch_summary_result(video_id)
    cache_service = Cache::CacheFactory.build(Chat::ChatGptService.cache_namespace)
    cache_service.exist?(video_id) ? cache_service.read(video_id) : nil
  end
end
