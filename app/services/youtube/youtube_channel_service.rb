module Youtube
  class YoutubeChannelService < YoutubeBaseService
    def self.fetch_channels_for_user(user_id)
      # TODO fetch all channels for user in one go
      channel_names = UserServices::UserDataService.user_items(user_id, :channels)
      channel_names.map { |name| fetch_cached(name, default_cache_namespace + "_channel_metadata") }.compact
    end

    def self.fetch_channel_metadata(channel_name)
      fetch_cached(channel_name, default_cache_namespace + "_channel_metadata") do
        fetch_channel_data(channel_name)
      end
    end

    def self.fetch_channel_videos(channel_name, channel_id)
      fetch_cached(channel_name, default_cache_namespace + "_channel_videos") do
        fetch_videos_from_api(channel_id)
      end
    end

    private

    def self.fetch_channel_data(channel_name)
      begin
        response = youtube_client.list_searches("snippet", q: channel_name, type: "channel")
        channel_id = response.items.first&.id&.channel_id

        response = youtube_client.list_channels("snippet,statistics", id: channel_id)
        channel = response.items.first

        {
          success: true,
          channel_id: channel.id,
          channel_name: channel_name,
          title: channel.snippet.title,
          description: channel.snippet.description,
          thumbnail_url: channel.snippet.thumbnails.high.url,
          subscriber_count: channel.statistics&.subscriber_count,
          video_count: channel.statistics&.video_count
        }
      rescue => e
        handle_youtube_error(e)
      end
    end

    def self.fetch_videos_from_api(channel_id)
      response = youtube_client.list_searches("snippet",
        channel_id: channel_id,
        order: "date",
        type: "video",
        max_results: 9
      )

      {
        success: true,
        videos: response.items.map { |item| format_video(item) }
      }
    rescue => e
      handle_youtube_error(e)
    end

    def self.extract_channel_name(url)
      if url.include?("/@")
        url.split("/@").last.split(/[?\/]/).first
      else
        nil
      end
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

    def self.find_channel_id_by_name(channel_name)
      response = youtube_client.list_searches("snippet", q: channel_name, type: "channel")
      response.items.first&.id&.channel_id
    rescue => e
      handle_youtube_error(e)
    end
  end
end
