class ChannelsController < ApplicationController
  include Paginatable

  def index
    @channels = Youtube::YoutubeChannelService.fetch_channels_for_user(Current.user.id)
  end

  def show
    @channel_name = params[:id]
    @channel = Youtube::YoutubeChannelService.fetch_channel_metadata(@channel_name)

    if !@channel[:success]
      flash[:error] = "Channel not found"
      redirect_to channels_path and return
    end

    UserServices::UserDataService.add_item(Current.user.id, :channels, @channel_name)

    # Get the current page token from params
    @current_token = params[:page_token]
    @per_page = 9 # YouTube API returns 9 videos per page
    @page = 1
    @total_pages = (@channel[:video_count].to_f / @per_page).ceil

    # Fetch videos for the current page
    response = Youtube::YoutubeChannelService.fetch_channel_videos(
      @channel_name,
      @channel[:channel_id],
      @per_page,
      @current_token
    )

    if !response[:success] || response[:videos].empty?
      @videos = []
    else
      @videos = response[:videos]
      @next_token = response[:next_page_token]
      @prev_token = response[:prev_page_token]
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "channel_videos_content",
          partial: "shared/video_grid",
          locals: {
            title: "Channel Videos",
            videos: @videos,
            path: channel_path(@channel_name),
            empty_message: "No videos found for this channel",
            youtube_pagination: true
          }
        )
      end
    end
  end

  def create_from_url
    channel_name = Youtube::YoutubeChannelService.extract_channel_name(params[:channel_url])
    return redirect_to channels_path, alert: "Invalid YouTube URL" unless channel_name

    respond_to do |format|
      format.html { redirect_to channel_path(channel_name, channel_url: params[:channel_url]) }
      format.turbo_stream { redirect_to channel_path(channel_name, channel_url: params[:channel_url]) }
    end
  end
end
