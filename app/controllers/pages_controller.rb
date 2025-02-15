class PagesController < PublicController
  include VideoSummariesHelper
  include Paginatable

  def about
  end

  def contact
  end

  def discover
    fetch_video_summaries(user_id: "master", type: :summaries_sponsered)
    respond_with_pagination(turbo_frame_id: "discover_content") { "pages/discover/content" }
  end
end 
