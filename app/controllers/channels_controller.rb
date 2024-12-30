class ChannelsController < ApplicationController
  include Paginatable

  def index
    @channels = Youtube::YoutubeChannelService.fetch_channels_for_user(Current.user.id)
  end

  def show
    @channel_name = params[:id]
    @channel = Youtube::YoutubeChannelService.fetch_channel_metadata(@channel_name)
    return redirect_to channels_path, alert: "Channel not found" unless @channel[:success]

    # Get videos for the channel
    response = Youtube::YoutubeChannelService.fetch_channel_videos(@channel_name, @channel[:channel_id], 9)

    if response.empty? || !response[:success]
      @videos = []
      return respond_with_pagination(turbo_frame_id: "channel_videos_content") { "channels/videos" }
    end

    # Extract video data and prepare for pagination
    all_videos = response[:videos]
    total_count = all_videos.length

    # Apply pagination to the videos array
    @page = (params[:page] || 1).to_i
    @per_page = 9
    @total_pages = (total_count.to_f / @per_page).ceil

    # Get the slice of videos for the current page
    start_index = (@page - 1) * @per_page
    end_index = start_index + @per_page - 1
    paginated_videos = all_videos[start_index..end_index] || []

    # Format the videos for display
    @videos = paginated_videos.map do |video|
      published_at = video[:published_at]
      published_at = published_at.is_a?(String) ? DateTime.parse(published_at) : published_at

      {
        video_id: video[:video_id],
        title: video[:title],
        channel: video[:channel_title],
        published_at: published_at,
        thumbnail: video[:thumbnail]
      }
    end.compact

    respond_with_pagination(turbo_frame_id: "channel_videos_content") { "channels/videos" }
  end

  def create_from_url
    channel_name = Youtube::YoutubeChannelService.extract_channel_name(params[:channel_url])
    return redirect_to channels_path, alert: "Invalid YouTube URL" unless channel_name

    redirect_to channel_path(channel_name, channel_url: params[:channel_url])
  end
end
