class ChannelsController < ApplicationController
  include AuthenticatedController

  def index
    @channels = Youtube::YoutubeChannelService.fetch_channels_for_user(Current.user.id)
  end

  def show
    channel_id = params[:id]
    return redirect_to channels_path, alert: "Channel not found" unless UserServices::UserDataService.has_item?(Current.user.id, :channels, channel_id)

    cache_service = Cache::FileCacheService.new("channels")
    @channel = cache_service.read(channel_id) if cache_service.exist?(channel_id)
    return redirect_to channels_path, alert: "Channel not found" unless @channel

    videos_cache = Cache::FileCacheService.new("channel_videos")
    @videos = videos_cache.fetch(channel_id) do
      Youtube::YoutubeChannelService.fetch_channel_videos(channel_id)
    end
  end

  def create
    channel_url = params[:channel_url]

    channel_data = Youtube::YoutubeChannelService.fetch_channel_from_url(channel_url)
    return redirect_to channels_path, alert: channel_data[:error] unless channel_data[:success]

    # Save channel data
    cache_service = Cache::FileCacheService.new("channels")
    cache_service.write(channel_data[:channel_id], channel_data)

    # Add to user's channels
    UserServices::UserDataService.add_item(Current.user.id, :channels, channel_data[:channel_id])

    redirect_to channels_path, notice: "Channel added successfully!"
  end

  private

  def load_channel(channel_id)
    return nil unless UserServices::UserDataService.has_item?(Current.user.id, :channels, channel_id)

    cache_service = Cache::FileCacheService.new("channels")
    cache_service.read(channel_id) if cache_service.exist?(channel_id)
  end
end
