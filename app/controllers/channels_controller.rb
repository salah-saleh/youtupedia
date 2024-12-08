class ChannelsController < ApplicationController
  before_action :authenticate!
  layout "dashboard"

  def index
    @channels = Youtube::YoutubeChannelService.fetch_channels_for_user(Current.user.id)
  end

  def show
    channel_id = params[:id]
    @channel = load_channel(channel_id)

    unless @channel
      channel_data = Youtube::YoutubeChannelService.fetch_channel_from_url(params[:channel_url])
      return redirect_to channels_path, alert: channel_data[:error] unless channel_data[:success]

      # Save channel data
      cache_service = Cache::FileCacheService.new("channels")
      cache_service.write(channel_data[:channel_id], channel_data)
      UserServices::UserDataService.add_item(Current.user.id, :channels, channel_data[:channel_id])

      @channel = channel_data
    end

    @videos = Youtube::YoutubeChannelService.fetch_channel_videos(channel_id)
  end

  def create_from_url
    channel_data = Youtube::YoutubeChannelService.fetch_channel_from_url(params[:channel_url])
    return redirect_to channels_path, alert: channel_data[:error] unless channel_data[:success]

    redirect_to channel_path(channel_data[:channel_id], channel_url: params[:channel_url])
  end

  private

  def load_channel(channel_id)
    return nil unless UserServices::UserDataService.has_item?(Current.user.id, :channels, channel_id)

    cache_service = Cache::FileCacheService.new("channels")
    cache_service.read(channel_id) if cache_service.exist?(channel_id)
  end
end
