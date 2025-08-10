class ChannelsController < ApplicationController
  include Paginatable
  public_actions :show

  def index
    channel_names = if params[:q].present?
      Search::ChannelSearchService.search_channel_names(params[:q], Current.user.id)
    else
      UserServices::UserDataService.user_items(Current.user.id, :channels)
    end

    return @channels = [] if channel_names.empty?

    # Apply pagination to channel_names
    paginated_channel_names = paginate(channel_names, per_page: 9)

    # Fetch all metadata in one batch
    @channels = Youtube::YoutubeChannelService.fetch_channels_metadata(paginated_channel_names)

    respond_with_pagination(turbo_frame_id: "channels_content") { "channels/index/content" }
  end

  def show
    @channel_name = params[:id]
    @channel = Youtube::YoutubeChannelService.fetch_channel_metadata(@channel_name)

    if !@channel[:success]
      flash[:error] = "Channel not found"
      redirect_to channels_path and return
    end

    UserServices::UserDataService.add_item(Current.user.id, :channels, @channel_name) if Current.user
    UserServices::UserDataService.add_item("master", :channels, @channel_name)

    # Get the current page token from params
    @current_token = params[:page_token]
    @per_page = 9 # YouTube API returns 9 videos per page
    @page = 1
    @total_pages = (@channel[:video_count].to_f / @per_page).ceil

    # Fetch videos for the current page
    if params[:q].present?
      response = Youtube::YoutubeChannelService.fetch_channel_videos_search(
        @channel_name,
        @channel[:channel_id],
        params[:q],
        @per_page,
        @current_token
      )
    else
      response = Youtube::YoutubeChannelService.fetch_channel_videos(
        @channel_name,
        @channel[:channel_id],
        @per_page,
        @current_token
      )
    end

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
