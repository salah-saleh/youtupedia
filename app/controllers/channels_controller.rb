class ChannelsController < ApplicationController
  layout "dashboard"

  def index
    cache_service = Cache::FileCacheService.new("channels")
    @channels = cache_service.fetch("user_123_channels") { [] }  # Mock user_id for now
  end

  def show
    cache_service = Cache::FileCacheService.new("channels")
    @channels = cache_service.fetch("user_123_channels") { [] }

    @channel = @channels.find { |c| c[:channel_id] == params[:id] }
    return redirect_to channels_path, alert: "Channel not found" unless @channel

    videos_cache = Cache::FileCacheService.new("channel_videos")
    @videos = videos_cache.fetch(@channel[:channel_id]) do
      YoutubeChannelService.fetch_channel_videos(@channel[:channel_id])
    end
  end

  def create
    channel_url = params[:channel_url]

    channel_data = YoutubeChannelService.fetch_channel_from_url(channel_url)
    return redirect_to channels_path, alert: channel_data[:error] unless channel_data[:success]

    cache_service = Cache::FileCacheService.new("channels")
    channels = cache_service.fetch("user_123_channels") { [] }

    unless channels.any? { |c| c[:channel_id] == channel_data[:channel_id] }
      channels << channel_data
      cache_service.write("user_123_channels", channels)
    end

    redirect_to channels_path, notice: "Channel added successfully!"
  end
end
