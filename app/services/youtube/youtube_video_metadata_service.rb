module Youtube
  class YoutubeVideoMetadataService < YoutubeBaseService
    MAX_VIDEOS_PER_REQUEST = 50 # YouTube API limit

    def self.fetch_metadata(video_id)
      # don't expire the cache
      fetch_cached(video_id, expires_in: nil) do
        fetch_from_api([ video_id ])[video_id]
      end
    end

    def self.fetch_metadata_batch(video_ids)
      # Filter out video IDs that are already in cache
      uncached_ids = video_ids.select do |id|
        !Rails.cache.exist?("#{default_cache_namespace}_#{id}")
      end

      # Fetch uncached videos in batches of 50 (YouTube API limit)
      unless uncached_ids.empty?
        uncached_ids.each_slice(MAX_VIDEOS_PER_REQUEST) do |batch|
          results = fetch_from_api(batch)
          results.each do |id, data|
            write_cached(id, data, expires_in: nil)
          end
        end
      end

      # Return all metadata (from cache and newly fetched)
      video_ids.map do |id|
        [ id, fetch_cached(id, expires_in: nil) { { success: false, error: "Video not found" } } ]
      end.to_h
    end

    private

    def self.fetch_from_api(video_ids)
      response = youtube_client.list_videos("snippet", id: video_ids.join(","))

      # Create a hash of successful responses
      results = response.items.map do |item|
        [ item.id, { success: true, metadata: format_metadata(item.snippet) } ]
      end.to_h

      # Add error responses for missing videos
      video_ids.each do |id|
        unless results[id]
          results[id] = { success: false, error: "Video not found" }
        end
      end

      results
    rescue => e
      error_response = handle_youtube_error(e)
      video_ids.map { |id| [ id, error_response ] }.to_h
    end

    def self.format_metadata(snippet)
      {
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
    end
  end
end
