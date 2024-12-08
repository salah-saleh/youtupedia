class YoutubeUrlsController < ApplicationController
  include YoutubeUrlHelper
  before_action :authenticate!
  layout "dashboard"

  def parse
    url = params[:url]
    return redirect_back fallback_location: root_path, alert: "Please enter a valid YouTube URL" unless url.present?

    if channel_url?(url)
      redirect_to create_from_url_channels_path(channel_url: url)
    else
      redirect_to create_from_url_summaries_path(youtube_url: url)
    end
  end
end
