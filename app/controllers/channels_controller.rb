class ChannelsController < ApplicationController
  def show
    if params[:channel_id].present?
      result = YoutubeChannelService.fetch_videos(params[:channel_id])
      if result[:success]
        @videos = result[:videos]
      else
        flash.now[:alert] = result[:error]
      end
    end
  end
end
