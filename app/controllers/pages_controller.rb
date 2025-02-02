class PagesController < PublicController
  include Paginatable

  def about
  end

  def contact
  end

  def discover
    # Get video IDs based on search or user's collection
    video_ids = if params[:q].present?
      Search::VideoSearchService.search_video_ids(params[:q], "master")
    else
      UserServices::UserDataService.user_items("master", :summaries)
    end

    return @summaries = [] if video_ids.empty?

    # Apply pagination to video IDs
    paginated_video_ids = paginate(video_ids)

    # Fetch metadata for paginated IDs
    metadata_results = Youtube::YoutubeVideoMetadataService.fetch_metadata_batch(paginated_video_ids)

    # Format results
    @summaries = metadata_results.map do |video_id, metadata|
      next unless metadata[:success]

      published_at = metadata[:metadata][:published_at]
      published_at = published_at.is_a?(String) ? DateTime.parse(published_at) : published_at

      {
        video_id: video_id,
        title: metadata[:metadata][:title],
        channel: metadata[:metadata][:channel_title],
        published_at: published_at,
        thumbnail: metadata[:metadata][:thumbnails][:high]
      }
    end.compact

    respond_with_pagination(turbo_frame_id: "discover_content")
  end
end 
