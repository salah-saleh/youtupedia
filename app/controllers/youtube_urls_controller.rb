class YoutubeUrlsController < ApplicationController
  before_action :authenticate!

  def parse
    url = params[:url]

    if url.present?
      if channel_url?(url)
        # Create channel first, then redirect to its show page
        channel_data = YoutubeChannelService.fetch_channel_from_url(url)

        if channel_data[:success]
          # Save channel and redirect to show page
          cache_service = Cache::FileCacheService.new("channels")
          channels = cache_service.fetch("channels_#{Current.user.id}") { [] }

          unless channels.any? { |c| c[:channel_id] == channel_data[:channel_id] }
            channels << channel_data
            cache_service.write("channels_#{Current.user.id}", channels)
          end

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
