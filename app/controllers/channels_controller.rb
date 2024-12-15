class ChannelsController < ApplicationController
  before_action :authenticate!
  layout "dashboard"

  def index
    @channels = Youtube::YoutubeChannelService.fetch_channels_for_user(Current.user.id)
  end

  def show
    @channel_name = params[:id]

    @channel = Youtube::YoutubeChannelService.fetch_channel_metadata(@channel_name)
    return redirect_to channels_path, alert: @channel[:error] unless @channel[:success]

    response = Youtube::YoutubeChannelService.fetch_channel_videos(@channel_name, @channel[:channel_id])
    redirect_to channels_path, alert: response[:error] unless response[:success]
    @videos = response[:videos]
    UserServices::UserDataService.add_item(Current.user.id, :channels, @channel_name)

    {
      channel: @channel,
      videos: @videos
    }
  end

  def create_from_url
    channel_name = Youtube::YoutubeChannelService.extract_channel_name(params[:channel_url])
    return redirect_to channels_path, alert: "Invalid YouTube URL" unless channel_name

    redirect_to channel_path(channel_name, channel_url: params[:channel_url])
  end
end
