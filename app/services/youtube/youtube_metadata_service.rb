module Youtube
  class YoutubeMetadataService
    def self.fetch_metadata(video_id)
      cache_service = Cache::FileCacheService.new("metadata")

      cache_service.fetch(video_id) do
        fetch_from_api(video_id)
      end
    rescue => e
      Rails.logger.error "Metadata Error: #{e.message}"
      { success: false, error: "Failed to fetch metadata: #{e.message}" }
    end

    private

    def self.fetch_from_api(video_id)
      client = Google::Apis::YoutubeV3::YouTubeService.new
      client.key = ENV["YOUTUBE_API_KEY"]

      response = client.list_videos("snippet", id: video_id)

      if response.items.any?
        snippet = response.items.first.snippet
        {
          success: true,
          metadata: {
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
        }
      else
        { success: false, error: "Video not found" }
      end
    end
  end
end
