module Youtube
  class YoutubeBaseService < BaseService
    protected

    def self.youtube_client
      @client ||= begin
        client = Google::Apis::YoutubeV3::YouTubeService.new
        client.key = ENV["YOUTUBE_API_KEY"]
        client
      end
    end

    def self.handle_youtube_error(error)
      handle_error(error, "YouTube API Error")
    end
  end
end
