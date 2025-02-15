# frozen_string_literal: true

# Provides common functionality for handling video summaries across controllers.
# This concern includes methods for fetching and formatting video summaries,
# with support for search and pagination.
module VideoSummariesHelper
  extend ActiveSupport::Concern

  private

  def fetch_video_summaries(user_id: "master", type: :summaries_sponsered)
    # Get video IDs based on search or user's collection
    video_ids = if params[:q].present? && params[:q].strip.length > 0
      Search::VideoSearchService.search_video_ids(params[:q], user_id, type: type)
    else
      UserServices::UserDataService.user_items(user_id, type)
    end

    @summaries = []
    
    unless video_ids.empty?
      # Apply pagination to video IDs
      paginated_video_ids = paginate(video_ids)

      # Fetch metadata for paginated IDs
      metadata_results = Youtube::YoutubeVideoMetadataService.fetch_metadata_batch(paginated_video_ids)

      # Format results
      @summaries = metadata_results.map do |video_id, metadata|
        next unless metadata[:success]

        format_video_metadata(video_id, metadata)
      end.compact
    end

    @summaries
  end

  def format_video_metadata(video_id, metadata)
    published_at = metadata[:metadata][:published_at]
    published_at = published_at.is_a?(String) ? DateTime.parse(published_at) : published_at

    {
      video_id: video_id,
      title: metadata[:metadata][:title],
      channel: metadata[:metadata][:channel_title],
      published_at: published_at,
      thumbnail: metadata[:metadata][:thumbnails][:high]
    }
  end
end 