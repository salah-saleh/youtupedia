module Youtube
  # Service for managing YouTube channel data and related video information
  # Handles channel metadata, video lists, and user channel associations
  class YoutubeChannelService < YoutubeBaseService
    # Fetches all channels from the cache or fetches missing channels from the API
    # @param paginated_channel_names [Array<String>] List of channel names
    # @return [Array<Hash>] List of channel metadata
    def self.fetch_channels_metadata(paginated_channel_names)
      paginated_channel_names.map { |name| fetch_channel_metadata(name) }.compact
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
      # first page should be always fetched from API
      force_block_execution = page_token.nil? ? true : false
      fetch_cached("#{channel_name}_#{page_token}", namespace: default_cache_namespace + "_channel_videos", expires_in: nil, force_block_execution: force_block_execution) do
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
        # Try to get channel directly by handle first
        response = youtube_client.list_channels(
          "snippet,statistics,contentDetails",
          for_handle: channel_name
        )

        # If no channel found by handle, return error
        if response.items.empty?
          return {
            success: false,
            error: "Channel not found. Please verify the channel handle."
          }
        end

        channel = response.items.first
        uploads_playlist_id = channel&.content_details&.related_playlists&.uploads
        {
          success: true,
          channel_id: channel.id,
          channel_name: channel_name,
          title: channel.snippet.title,
          description: channel.snippet.description,
          thumbnail_url: channel.snippet.thumbnails.high.url,
          subscriber_count: channel.statistics&.subscriber_count,
          video_count: channel.statistics&.video_count,
          view_count: channel.statistics&.view_count,
          uploads_playlist_id: uploads_playlist_id
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
    # Fetches videos using the channel's uploads playlist for reliable pagination
    # @param channel_id [String] YouTube channel ID
    # @param page_size [Integer] Number of videos per page (max 50 for API, we use 9 by default)
    # @param page_token [String, nil] Token for the next page returned from the previous call
    # @return [Hash]
    #   @option [Boolean] :success Operation status
    #   @option [Array<Hash>] :videos List of formatted video metadata
    #   @option [String, nil] :next_page_token Token for the next page
    #   @option [String, nil] :prev_page_token Token for the previous page
    def self.fetch_videos_from_api(channel_id, page_size = 9, page_token = nil)
      # Resolve uploads playlist id (cached) and paginate via playlistItems for reliable tokens
      uploads_playlist_id = fetch_uploads_playlist_id(channel_id)
      return uploads_playlist_id if uploads_playlist_id.is_a?(Hash) && uploads_playlist_id[:success] == false

      response = youtube_client.list_playlist_items(
        "snippet,contentDetails",
        playlist_id: uploads_playlist_id,
        max_results: page_size,
        page_token: page_token
      )

      {
        success: true,
        videos: response.items.map { |item|
          video_id = item&.content_details&.video_id || item&.snippet&.resource_id&.video_id
          {
            video_id: video_id,
            title: item.snippet.title,
            description: item.snippet.description,
            thumbnail: item.snippet.thumbnails&.high&.url || item.snippet.thumbnails&.default&.url,
            published_at: item&.content_details&.video_published_at || item.snippet.published_at,
            channel_title: item.snippet.channel_title
          }
        },
        next_page_token: response.next_page_token,
        prev_page_token: response.prev_page_token
      }
    rescue => e
      handle_youtube_error(e)
    end

    # Returns the uploads playlist ID for a channel
    # - Uses cache for efficiency and no expiry to minimize quota usage
    # - Falls back with a structured error if the channel cannot be found
    # @param channel_id [String]
    # @return [String] uploads playlist id or
    #         [Hash] error hash with { success: false, error: String }
    def self.fetch_uploads_playlist_id(channel_id)
      fetch_cached(channel_id, namespace: default_cache_namespace + "_uploads_playlist", expires_in: nil) do
        ch_response = youtube_client.list_channels("contentDetails", id: channel_id)
        if ch_response.items.empty?
          {
            success: false,
            error: "Channel not found for contentDetails"
          }
        else
          ch_response.items.first.content_details.related_playlists.uploads
        end
      end
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
