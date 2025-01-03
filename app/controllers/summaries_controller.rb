class SummariesController < ApplicationController
  include YoutubeUrlHelper
  include SummaryDataHelper
  include Paginatable
  public_actions [ :show, :create_from_url, :check_status ]

  def create_from_url
    video_id = extract_video_id(params[:youtube_url])
    return redirect_to root_path, alert: "Invalid YouTube URL" unless video_id
    redirect_to summary_path(id: video_id)
  end

  def show
    @video_id = params[:id]
    @metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(@video_id)
    return redirect_to root_path, alert: "This video is not possible to summarize. #{@metadata[:error]}" unless @metadata[:success]

    # Try to get existing data from cache
    @transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(@video_id)
    # Only fetch summary if we have a successful transcript
    @summary = @transcript&.dig(:success) ? Chat::ChatGptService.fetch_summary(@video_id) : nil

    # If no data exists, try to schedule a job
    if (!@transcript || !@summary) && SummaryJob.schedule(@video_id)
      UserServices::UserDataService.add_item(Current.user.id, :summaries, @video_id) if Current.user
    end

    # Build summary data
    @summary_data = build_summary_data(@video_id, @metadata, @transcript, @summary)
  end

  def index
    video_ids = UserServices::UserDataService.user_items(Current.user.id, :summaries)
    return @summaries = [] if video_ids.empty?

    # Apply pagination to video_ids
    paginated_video_ids = paginate(video_ids)

    # Fetch all metadata in one batch
    metadata_results = Youtube::YoutubeVideoMetadataService.fetch_metadata_batch(paginated_video_ids)

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

    respond_with_pagination(turbo_frame_id: "summaries_content") { "summaries/index/content" }
  end

  def check_status
    video_id = params[:id]
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    # Only fetch summary if we have a successful transcript
    summary = transcript&.dig(:success) ? Chat::ChatGptService.fetch_summary(video_id) : nil

    result = build_summary_data(video_id, metadata, transcript, summary)

    respond_to do |format|
      format.json { render json: build_status_response(result) }
      format.turbo_stream { render_status_stream(params[:frame_id], result) }
    end
  end

  def ask_gpt
    question = params[:question]
    video_id = params[:id]
    transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)

    result = Chat::ChatGptService.answer_question(video_id, question, transcript[:transcript_full], metadata)

    if result[:success]
      render json: { success: true, answer: result[:answer] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def build_status_response(result)
    if result[:loading]
      { status: "processing" }
    else
      if result[:error]
        { status: "failed", error: result[:error] }
      else
        { status: "completed", summary: result }
      end
    end
  end

  def render_status_stream(frame_id, result)
    partial_name = "summaries/show/#{frame_id}_section"
    render turbo_stream: turbo_stream.update(frame_id, partial: partial_name, locals: { summary: result })
  end
end
