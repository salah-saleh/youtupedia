class YoutubeUrlsController < ApplicationController
  include YoutubeUrlHelper

  # The parse action handles YouTube URLs submitted by users and redirects them
  # to the appropriate page based on the URL type:
  # - YouTube channel URLs -> channels page
  # - YouTube video URLs -> summaries page
  # - Other text -> search page
  #
  # @param url [String] The YouTube URL or search query submitted by the user
  def parse
    url = params[:url]
    return redirect_back fallback_location: root_path, alert: "Please enter a valid YouTube URL" unless url.present?

    if channel_url?(url)
      redirect_to create_from_url_channels_path(channel_url: url)
    elsif video_url?(url)
      redirect_to create_from_url_summaries_path(youtube_url: url)
    else
      redirect_to create_from_url_search_index_path(q: url)
    end
  end
end
