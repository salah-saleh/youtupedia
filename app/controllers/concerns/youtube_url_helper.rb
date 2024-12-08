module YoutubeUrlHelper
  extend ActiveSupport::Concern

  private

  def extract_video_id(url)
    return nil unless url.present?

    if url.include?("youtu.be/")
      url.split("youtu.be/").last.split("?").first
    elsif url.include?("v=")
      url.split("v=").last.split("&").first
    end
  end

  def channel_url?(url)
    url.include?("/channel/") ||
    url.include?("/c/") ||
    url.include?("/user/") ||
    url.include?("/@")
  end
end
