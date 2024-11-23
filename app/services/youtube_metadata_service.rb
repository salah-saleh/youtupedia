class YoutubeMetadataService
  def self.fetch_metadata(video_id)
    client = Google::Apis::YoutubeV3::YouTubeService.new
    client.key = ENV["YOUTUBE_API_KEY"]

    begin
      Rails.logger.debug("Fetching video metadata for video_id: #{video_id}")
      response = client.list_videos(
        "snippet",
        id: video_id
      )
      Rails.logger.debug("Response: #{response.inspect}")

      if response.items.any?
        video = response.items.first.snippet
        {
          success: true,
          title: video.title,
          channel: video.channel_title,
          date: video.published_at.strftime("%B %d, %Y"),
          thumbnail: video.thumbnails.high.url,
          description: video.description
        }
      else
        {
          success: false,
          error: "Video not found"
        }
      end
    rescue => e
      Rails.logger.error "YouTube API Error: #{e.message}"
      {
        success: false,
        error: "Failed to fetch video metadata: #{e.message}"
      }
    end
  end
end
