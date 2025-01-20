module Youtube
  # Base class for YouTube services providing API client and error handling
  class YoutubeBaseService < BaseService
    include Cacheable

    class << self
      def youtube_client
        @client ||= begin
          client = Google::Apis::YoutubeV3::YouTubeService.new
          client.key = ENV["YOUTUBE_API_KEY"]
          client
        end
      end

      def handle_youtube_error(error)
        handle_error(error, "YouTube API Error")
      end
    end

    def handle_youtube_error(error)
      self.class.handle_youtube_error(error)
    end
  end
end
