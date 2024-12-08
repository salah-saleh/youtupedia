class YoutubeUrlsController < ApplicationController
  include YoutubeUrlHelper
  before_action :authenticate!
  layout "dashboard"

  def parse
    url = params[:url]
    return redirect_back fallback_location: root_path, alert: "Please enter a valid YouTube URL" unless url.present?

    if channel_url?(url)
      handle_channel_url(url)
    else
      redirect_to create_from_url_summaries_path(youtube_url: url)
    end
  end

  private

  def handle_channel_url(url)
    channel_data = Youtube::YoutubeChannelService.fetch_channel_from_url(url)

    if channel_data[:success]
      cache_service = Cache::FileCacheService.new("channels")
      cache_service.write(channel_data[:channel_id], channel_data)
      UserServices::UserDataService.add_item(Current.user.id, :channels, channel_data[:channel_id])
      redirect_to channel_path(channel_data[:channel_id])
    else
      redirect_back fallback_location: root_path, alert: channel_data[:error]
    end
  end
end
