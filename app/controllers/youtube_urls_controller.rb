class YoutubeUrlsController < ApplicationController
  before_action :authenticate!
  layout "dashboard"

  def parse
    url = params[:url]

    if url.present?
      if channel_url?(url)
        # Create channel first, then redirect to its show page
        channel_data = Youtube::YoutubeChannelService.fetch_channel_from_url(url)

        if channel_data[:success]
          # Save channel data
          cache_service = Cache::FileCacheService.new("channels")
          cache_service.write(channel_data[:channel_id], channel_data)

          # Add to user's channels
          UserServices::UserDataService.add_item(Current.user.id, :channels, channel_data[:channel_id])

          redirect_to channel_path(channel_data[:channel_id])
        else
          redirect_back fallback_location: root_path, alert: channel_data[:error]
        end
      else
        redirect_to create_from_url_summaries_path(youtube_url: url)
      end
    else
      redirect_back fallback_location: root_path, alert: "Please enter a valid YouTube URL"
    end
  end

  private

  def channel_url?(url)
    url.include?("/channel/") ||
    url.include?("/c/") ||
    url.include?("/user/") ||
    url.include?("/@")
  end
end
