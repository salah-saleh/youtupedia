class YoutubeChannelService
  def self.fetch_videos(channel_id)
    cache_service = Cache::FileCacheService.new("channels")

    cache_service.fetch(channel_id) do
      fetch_from_api(channel_id)
    end
  rescue => e
    Rails.logger.error "Channel API Error: #{e.message}"
    { success: false, error: "Failed to fetch channel videos: #{e.message}" }
  end

  private

  def self.fetch_from_api(channel_id)
    client = Google::Apis::YoutubeV3::YouTubeService.new
    client.key = ENV["YOUTUBE_API_KEY"]

    channel_response = client.list_channels(
      "contentDetails",
      id: channel_id
    )

    uploads_playlist_id = channel_response.items.first.content_details.related_playlists.uploads
    videos = fetch_playlist_videos(client, uploads_playlist_id)

    {
      success: true,
      videos: videos,
      cached_at: Time.current
    }
  end

  def self.fetch_playlist_videos(client, playlist_id)
    videos = []
    next_page_token = nil

    loop do
      playlist_response = client.list_playlist_items(
        "snippet",
        playlist_id: playlist_id,
        max_results: 50,
        page_token: next_page_token
      )

      playlist_response.items.each do |item|
        video_id = item.snippet.resource_id.video_id
        videos << {
          video_id: video_id,
          title: item.snippet.title,
          url: "https://www.youtube.com/watch?v=#{video_id}",
          published_at: item.snippet.published_at,
          description: item.snippet.description
        }
      end

      next_page_token = playlist_response.next_page_token
      break unless next_page_token
    end

    videos
  end
end
