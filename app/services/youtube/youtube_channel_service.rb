module Youtube
  class YoutubeChannelService
    def self.fetch_channel_from_url(url)
      channel_id = extract_channel_id(url)
      return { success: false, error: "Invalid channel URL" } unless channel_id

      fetch_channel_data(channel_id)
    end

    def self.fetch_channel_data(channel_id)
      client = Google::Apis::YoutubeV3::YouTubeService.new
      client.key = ENV["YOUTUBE_API_KEY"]

      begin
        response = client.list_channels("snippet,statistics", id: channel_id)
        channel = response.items.first

        return { success: false, error: "Channel not found" } unless channel

        {
          success: true,
          channel_id: channel.id,
          title: channel.snippet.title,
          description: channel.snippet.description,
          thumbnail_url: channel.snippet.thumbnails.high.url,
          subscriber_count: channel.statistics.subscriber_count,
          video_count: channel.statistics.video_count
        }
      rescue => e
        Rails.logger.error "YouTube API Error: #{e.message}"
        { success: false, error: "Failed to fetch channel data" }
      end
    end

    def self.fetch_channel_videos(channel_id)
      client = Google::Apis::YoutubeV3::YouTubeService.new
      client.key = ENV["YOUTUBE_API_KEY"]

      begin
        response = client.list_searches("snippet",
          channel_id: channel_id,
          order: "date",
          type: "video",
          max_results: 9
        )

        response.items.map do |item|
          {
            video_id: item.id.video_id,
            title: item.snippet.title,
            description: item.snippet.description,
            thumbnail: item.snippet.thumbnails.high.url,
            published_at: item.snippet.published_at,
            channel_title: item.snippet.channel_title
          }
        end
      rescue => e
        Rails.logger.error "YouTube API Error: #{e.message}"
        []
      end
    end

    private

    def self.extract_channel_id(url)
      if url.include?("youtube.com/channel/")
        url.split("channel/").last.split("?").first
      elsif url.include?("youtube.com/c/") || url.include?("youtube.com/@")
        # For custom URLs, we need to search by channel name
        channel_name = url.split(/c\/|@/).last.split("?").first
        find_channel_id_by_name(channel_name)
      end
    end

    def self.find_channel_id_by_name(channel_name)
      client = Google::Apis::YoutubeV3::YouTubeService.new
      client.key = ENV["YOUTUBE_API_KEY"]

      begin
        response = client.list_searches("snippet", q: channel_name, type: "channel")
        response.items.first&.id&.channel_id
      rescue => e
        Rails.logger.error "YouTube API Error: #{e.message}"
        nil
      end
    end
  end
end
