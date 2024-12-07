module Youtube
  class YoutubeChannelService < YoutubeBaseService
    def self.fetch_channels_for_user(user_id)
      channel_ids = UserServices::UserDataService.user_items(user_id, :channels)
      channel_ids.map { |id| fetch_cached(id, "channels") }.compact
    end

    def self.fetch_channel_from_url(url)
      channel_id = extract_channel_id(url)
      return { success: false, error: "Invalid channel URL" } unless channel_id

      fetch_channel_data(channel_id)
    end

    def self.fetch_channel_videos(channel_id)
      fetch_cached("videos_#{channel_id}", "channel_videos") do
        fetch_videos_from_api(channel_id)
      end
    end

    private

    def self.fetch_channel_data(channel_id)
      response = youtube_client.list_channels("snippet,statistics", id: channel_id)
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
      handle_youtube_error(e)
    end

    def self.fetch_videos_from_api(channel_id)
      response = youtube_client.list_searches("snippet",
        channel_id: channel_id,
        order: "date",
        type: "video",
        max_results: 9
      )

      response.items.map { |item| format_video(item) }
    rescue => e
      handle_youtube_error(e)
    end

    def self.format_video(item)
      {
        video_id: item.id.video_id,
        title: item.snippet.title,
        description: item.snippet.description,
        thumbnail: item.snippet.thumbnails.high.url,
        published_at: item.snippet.published_at,
        channel_title: item.snippet.channel_title
      }
    end

    def self.extract_channel_id(url)
      if url.include?("youtube.com/channel/")
        url.split("channel/").last.split("?").first
      elsif url.include?("youtube.com/c/") || url.include?("youtube.com/@")
        channel_name = url.split(/c\/|@/).last.split("?").first
        find_channel_id_by_name(channel_name)
      end
    end

    def self.find_channel_id_by_name(channel_name)
      response = youtube_client.list_searches("snippet", q: channel_name, type: "channel")
      response.items.first&.id&.channel_id
    rescue => e
      handle_youtube_error(e)
    end
  end
end
