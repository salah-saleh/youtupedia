module Youtube
  class YoutubeVideoMetadataService < YoutubeBaseService
    def self.fetch_metadata(video_id)
      fetch_cached(video_id, "metadata") do
        fetch_from_api(video_id)
      end
    end

    private

    def self.fetch_from_api(video_id)
      response = youtube_client.list_videos("snippet", id: video_id)

      if response.items.any?
        snippet = response.items.first.snippet
        {
          success: true,
          metadata: format_metadata(snippet)
        }
      else
        { success: false, error: "Video not found" }
      end
    rescue => e
      handle_youtube_error(e)
    end

    def self.format_metadata(snippet)
      {
        title: snippet.title,
        description: snippet.description,
        channel_title: snippet.channel_title,
        channel_id: snippet.channel_id,
        published_at: snippet.published_at,
        thumbnails: {
          default: snippet.thumbnails.default&.url,
          medium: snippet.thumbnails.medium&.url,
          high: snippet.thumbnails.high&.url,
          standard: snippet.thumbnails.standard&.url,
          maxres: snippet.thumbnails.maxres&.url
        },
        category_id: snippet.category_id,
        tags: snippet.tags,
        live_broadcast_content: snippet.live_broadcast_content
      }
    end
  end
end
