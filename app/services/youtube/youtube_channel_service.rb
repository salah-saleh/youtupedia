module Youtube
  # Service for managing YouTube channel data and related video information
  # Handles channel metadata, video lists, and user channel associations
  class YoutubeChannelService < YoutubeBaseService
    # Fetches all channels associated with a user
    # @param user_id [Integer] User ID
    # @return [Array<Hash>] List of channel metadata
    def self.fetch_channels_for_user(user_id)
      # TODO fetch all channels for user in one go
      channel_names = UserServices::UserDataService.user_items(user_id, :channels)
      channel_names.map { |name| fetch_cached(name, namespace: default_cache_namespace + "_channel_metadata", expires_in: nil) }.compact
    end

    # Fetches metadata for a specific channel
    # @param channel_name [String] Channel name or handle
    # @return [Hash] Channel metadata with success status
    def self.fetch_channel_metadata(channel_name)
      fetch_cached(channel_name, namespace: default_cache_namespace + "_channel_metadata", expires_in: nil) do
        fetch_channel_data(channel_name)
      end
    end

    # Fetches videos from a channel with pagination support
    # @param channel_name [String] Channel name
    # @param channel_id [String] YouTube channel ID
    # @param page_size [Integer] Number of videos per page
    # @param page_token [String] Token for the next page (optional)
    # @return [Hash] List of videos with pagination info and success status
    def self.fetch_channel_videos(channel_name, channel_id, page_size = 9, page_token = nil)
      fetch_cached("#{channel_name}_#{page_token}", namespace: default_cache_namespace + "_channel_videos") do
        fetch_videos_from_api(channel_id, page_size, page_token)
      end
    end

    private

    # Fetches detailed channel information from YouTube API
    # @param channel_name [String] Channel name or handle
    # @return [Hash] Channel metadata with success status
    #   @option [Boolean] :success Operation status
    #   @option [String] :channel_id YouTube channel ID
    #   @option [String] :title Channel title
    #   @option [String] :description Channel description
    #   @option [String] :thumbnail_url Channel thumbnail URL
    #   @option [Integer] :subscriber_count Number of subscribers
    #   @option [Integer] :video_count Total video count
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
          video_count: channel.statistics&.video_count,
          view_count: channel.statistics&.view_count
        }
      rescue => e
        handle_youtube_error(e)
      end
    end

    # Fetches videos for a channel from YouTube API with pagination
    # @param channel_id [String] YouTube channel ID
    # @param page_size [Integer] Number of videos per page
    # @param page_token [String] Token for the next page
    # @return [Hash] List of videos with pagination info and success status
    #   @option [Boolean] :success Operation status
    #   @option [Array<Hash>] :videos List of video metadata
    #   @option [String] :next_page_token Token for the next page
    #   @option [String] :prev_page_token Token for the previous page
    def self.fetch_videos_from_api(channel_id, page_size = 9, page_token = nil)
      response = youtube_client.list_searches("snippet",
        channel_id: channel_id,
        order: "date",
        type: "video",
        max_results: page_size,
        page_token: page_token
      )

      {
        success: true,
        videos: response.items.map { |item|
          {
            video_id: item.id.video_id,
            title: item.snippet.title,
            description: item.snippet.description,
            thumbnail: item.snippet.thumbnails.high.url,
            published_at: item.snippet.published_at,
            channel_title: item.snippet.channel_title
          }
        },
        next_page_token: response.next_page_token,
        prev_page_token: response.prev_page_token
      }
    rescue => e
      handle_youtube_error(e)
    end

    # Extracts channel name from a YouTube URL
    # @param url [String] YouTube channel URL
    # @return [String, nil] Channel name or nil if not found
    def self.extract_channel_name(url)
      if url.include?("/@")
        url.split("/@").last.split(/[?\/]/).first
      else
        nil
      end
    end

    # Formats video data from YouTube API response
    # @param item [Google::Apis::YoutubeV3::SearchResult] YouTube API response item
    # @return [Hash] Formatted video metadata
    #   @option [String] :video_id YouTube video ID
    #   @option [String] :title Video title
    #   @option [String] :description Video description
    #   @option [String] :thumbnail Thumbnail URL
    #   @option [DateTime] :published_at Publication date
    #   @option [String] :channel_title Channel name
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

    # Finds channel ID by channel name using YouTube API
    # @param channel_name [String] Channel name to search
    # @return [String, nil] YouTube channel ID or nil if not found
    def self.find_channel_id_by_name(channel_name)
      response = youtube_client.list_searches("snippet", q: channel_name, type: "channel")
      response.items.first&.id&.channel_id
    rescue => e
      handle_youtube_error(e)
    end
  end
end
