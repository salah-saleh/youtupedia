class SummariesController < ApplicationController
  include YoutubeUrlHelper
  include SummaryDataHelper

  before_action :authenticate!
  layout "dashboard"
  before_action :load_video_data, only: [ :show, :ask_gpt ]

  def create_from_url
    video_id = extract_video_id(params[:youtube_url])
    return redirect_to root_path, alert: "Invalid YouTube URL" unless video_id
    redirect_to summary_path(id: video_id)
  end

  def show
    UserServices::UserDataService.add_item(Current.user.id, :summaries, @video_id)
    result = fetch_summary_result(@video_id)

    if result.nil?
      Chat::ChatGptService.process_async(@video_id, @transcript[:transcript_full], @metadata)
    end

    @summary = build_summary_data(@video_id, @metadata, @transcript, result)
  end

  def index
    video_ids = UserServices::UserDataService.user_items(Current.user.id, :summaries)
    @summaries = video_ids.map do |video_id|
      metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)
      published_at = metadata[:metadata][:published_at]
      published_at = published_at.is_a?(Time) ? published_at : (published_at.present? ? Time.parse(published_at) : nil)
      if metadata[:success]
        {
          video_id: video_id,
          title: metadata[:metadata][:title],
          channel: metadata[:metadata][:channel_title],
          published_at: published_at,
          thumbnail: metadata[:metadata][:thumbnails][:high]
        }
      end
    end.compact
  end

  def check_status
    video_id = params[:id]
    result = fetch_summary_result(video_id)

    respond_to do |format|
      format.json { render json: build_status_response(result) }
      format.turbo_stream { render_status_stream(params[:frame_id], result) }
    end
  end

  def ask_gpt
    question = params[:question]
    result = Chat::ChatGptService.answer_question(@video_id, question, @transcript[:transcript_full], @metadata)

    if result[:success]
      render json: { success: true, answer: result[:answer] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def load_video_data
    @video_id = params[:id]
    @metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(@video_id)
    return redirect_to root_path, alert: @metadata[:error] unless @metadata[:success]

    @transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(@video_id)
    redirect_to root_path, alert: @transcript[:error] unless @transcript[:success]
  end

  def build_status_response(result)
    if result
      if result[:success]
        { status: "completed", summary: result }
      else
        { status: "failed", error: result[:error] }
      end
    else
      { status: "processing" }
    end
  end

  def render_status_stream(frame_id, result)
    summary_data = if result
      if result[:success]
        result.merge(loading: false)
      else
        {
          loading: false,
          error: result[:error],
          tldr: "Oops! #{result[:error]}",
          takeaways: [],
          tags: [],
          summary: ""
        }
      end
    else
      {
        loading: true,
        tldr: "",
        takeaways: [],
        tags: [],
        summary: ""
      }
    end

    partial_name = frame_id == "summary" ? "summary_detail_section" : "#{frame_id}_section"
    render turbo_stream: turbo_stream.update(frame_id, partial: partial_name, locals: { summary: summary_data })
  end
end
