class SummariesController < ApplicationController
  include YoutubeUrlHelper
  include SummaryDataHelper
  include VideoSummariesHelper
  include Paginatable
  public_actions [ :show, :create_from_url, :check_status, :expand_takeaway ]

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
    @summary = @transcript&.dig(:success) ? Ai::LlmSummaryService.fetch_summary(@video_id) : nil

    # If no data exists, try to schedule a job
    # If transcript is not successful, retry by running the job again
    SummaryJob.schedule(@video_id) if !@transcript || !@transcript[:success] || !@summary

    UserServices::UserDataService.add_item(Current.user.id, :summaries, @video_id) if Current.user
    UserServices::UserDataService.add_item("master", :summaries, @video_id)

    # Build summary data
    # If transcript is not successful, return nil initially
    @summary_data = build_summary_data(@video_id, @metadata, @transcript, @summary)
  end

  def index
    fetch_video_summaries(user_id: Current.user.id, type: :summaries)

    respond_with_pagination(turbo_frame_id: "summaries_content") { "summaries/index/content" }
  end

  def check_status
    video_id = params[:id]
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
    transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    # Only fetch summary if we have a successful transcript
    summary = transcript&.dig(:success) ? Ai::LlmSummaryService.fetch_summary(video_id) : nil

    result = build_summary_data(video_id, metadata, transcript, summary)

    respond_to do |format|
      format.json { render json: build_status_response(result) }
      format.turbo_stream { render_status_stream(params[:frame_id], result) }
    end
  end

  def expand_takeaway
    video_id = params[:id]
    index = params[:index].to_i

    # Get the transcript and summary
    transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    summary = Ai::LlmSummaryService.fetch_summary(video_id)

    return head :not_found unless transcript&.dig(:success) && summary&.dig(:success)

    # return if already expanded
    if summary[:contents][index]&.dig(:expanded_takeaway)
      render partial: "summaries/show/expanded_takeaway",
        locals: { expanded: summary[:contents][index], index: index }
      return
    end

    # Get the specific takeaway content
    content = summary[:contents][index]
    return head :not_found unless content

    # Get expanded content
    expanded = Ai::LlmTakeawayExpanderService.expand_takeaway(
      video_id,
      index,
      transcript[:transcript_full],
      content[:topic],
      content[:takeaway]
    )

    if expanded[:success]
      render partial: "summaries/show/expanded_takeaway",
             locals: { expanded: expanded, index: index }
    else
      render turbo_stream: turbo_stream.update("expanded-takeaway-#{index}",
        partial: "shared/error_message",
        locals: { message: "Failed to expand takeaway. Please try again." })
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
