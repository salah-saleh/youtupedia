class YoutubeMetadataService
  CACHE_DIR = Rails.root.join("tmp/metadata")

  def self.fetch_metadata(video_id)
    # Create cache directory if it doesn't exist
    FileUtils.mkdir_p(CACHE_DIR) unless Dir.exist?(CACHE_DIR)
    cache_file = CACHE_DIR.join("#{video_id}.json")

    if File.exist?(cache_file)
      Rails.logger.debug("Loading metadata from cache for video_id: #{video_id}")
      JSON.parse(File.read(cache_file), symbolize_names: true)
    else
      Rails.logger.debug("Fetching new metadata for video_id: #{video_id}")
      fetch_and_cache_metadata(video_id, cache_file)
    end
  rescue => e
    Rails.logger.error "Metadata Error: #{e.message}"
    { success: false, error: "Failed to fetch metadata: #{e.message}" }
  end

  private

  def self.fetch_and_cache_metadata(video_id, cache_file)
    client = Google::Apis::YoutubeV3::YouTubeService.new
    client.key = ENV["YOUTUBE_API_KEY"]

    response = client.list_videos("snippet", id: video_id)

    if response.items.any?
      snippet = response.items.first.snippet
      metadata = {
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

      result = {
        success: true,
        metadata: metadata
      }

      Rails.logger.debug("Caching metadata for video_id: #{video_id}")
      File.write(cache_file, result.to_json)

      result
    else
      { success: false, error: "Video not found" }
    end
  end
end
