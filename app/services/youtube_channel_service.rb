class YoutubeChannelService
  CACHE_DIR = Rails.root.join("tmp/channels")

  def self.fetch_videos(channel_id)
    # Create cache directory if it doesn't exist
    FileUtils.mkdir_p(CACHE_DIR) unless Dir.exist?(CACHE_DIR)
    cache_file = CACHE_DIR.join("#{channel_id}.json")

    if File.exist?(cache_file)
      Rails.logger.debug("Loading channel videos from cache for channel_id: #{channel_id}")
      JSON.parse(File.read(cache_file), symbolize_names: true)
    else
      Rails.logger.debug("Fetching new channel videos for channel_id: #{channel_id}")
      fetch_and_cache_videos(channel_id, cache_file)
    end
  rescue => e
    Rails.logger.error "Channel API Error: #{e.message}"
    { success: false, error: "Failed to fetch channel videos: #{e.message}" }
  end

  private

  def self.fetch_and_cache_videos(channel_id, cache_file)
    client = Google::Apis::YoutubeV3::YouTubeService.new
    client.key = ENV["YOUTUBE_API_KEY"]

    begin
      channel_response = client.list_channels(
        "contentDetails",
        id: channel_id
      )

      uploads_playlist_id = channel_response.items.first.content_details.related_playlists.uploads
      videos = []
      next_page_token = nil

      loop do
        playlist_response = client.list_playlist_items(
          "snippet",
          playlist_id: uploads_playlist_id,
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

      result = {
        success: true,
        videos: videos,
        cached_at: Time.current
      }

      Rails.logger.debug("Caching channel videos for channel_id: #{channel_id}")
      File.write(cache_file, result.to_json)

      result
    rescue => e
      Rails.logger.error "Channel API Error: #{e.message}"
      { success: false, error: "Failed to fetch channel videos: #{e.message}" }
    end
  end
end
