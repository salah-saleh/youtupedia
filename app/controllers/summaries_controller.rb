class SummariesController < ApplicationController
  before_action :authenticate!
  layout "dashboard"

  def create_from_url
    video_id = extract_video_id(params[:youtube_url])
    return redirect_to root_path, alert: "Invalid YouTube URL" unless video_id

    # Redirect to show page, which will handle the summary creation if needed
    redirect_to summary_path(id: video_id)
  end

  def show
    @video_id = params[:id]

    @metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(@video_id)
    return redirect_to root_path, alert: @metadata[:error] unless @metadata[:success]

    @transcript = Youtube::YoutubeVideoTranscriptService.fetch_transcript(@video_id)
    return redirect_to root_path, alert: @transcript[:error] unless @transcript[:success]

    UserServices::UserDataService.add_item(Current.user.id, :summaries, @video_id)

    cache_service = Cache::FileCacheService.new(Chat::ChatGptService.cache_namespace)
    result = cache_service.exist?(@video_id) ? cache_service.read(@video_id) : nil
    if result
      # Show loading state
      if result[:success]
        @summary = {
          video_id: @video_id,
          title: @metadata.dig(:metadata, :title),
          channel: @metadata.dig(:metadata, :channel_title),
          date: @metadata.dig(:metadata, :published_at),
          thumbnail: @metadata.dig(:metadata, :thumbnails, :high),
          description: @metadata.dig(:metadata, :description),
          transcript: @transcript[:transcript_segmented],
          loading: false,
          tldr: result[:tldr],
          takeaways: result[:takeaways],
          tags: result[:tags],
          summary: result[:summary]
        }
      else
        @summary = {
          video_id: @video_id,
          title: @metadata.dig(:metadata, :title),
          channel: @metadata.dig(:metadata, :channel_title),
          date: @metadata.dig(:metadata, :published_at),
          thumbnail: @metadata.dig(:metadata, :thumbnails, :high),
          description: @metadata.dig(:metadata, :description),
          transcript: @transcript[:transcript_segmented],
          loading: false,
          tldr: result[:error],
          takeaways: [],
          tags: [],
          summary: ""
        }
      end
    else
      # Schedule the summary generation
      Chat::ChatGptService.process_async(@video_id, @transcript[:transcript_full], @metadata)

      # Show loading state
      @summary = {
        video_id: @video_id,
        title: @metadata.dig(:metadata, :title),
        channel: @metadata.dig(:metadata, :channel_title),
        date: @metadata.dig(:metadata, :published_at),
        thumbnail: @metadata.dig(:metadata, :thumbnails, :high),
        description: @metadata.dig(:metadata, :description),
        transcript: @transcript[:transcript_segmented],
        loading: true,
        tldr: "",
        takeaways: [],
        tags: [],
        summary: ""
      }
    end
  end

  def index
    # Only show summaries belonging to the current user
    @summaries = UserServices::UserDataService.user_items(Current.user.id, :summaries).map do |video_id|
      cache_service = Cache::FileCacheService.new(Chat::ChatGptService.cache_namespace)
      if cache_service.exist?(video_id)
        result = cache_service.read(video_id)
        if result[:success]
          {
            video_id: video_id,
            title: result[:title],
            channel: result[:channel],
            published_at: result[:date],
            thumbnail: result[:thumbnail]
          }
        end
      end
    end.compact
  end

  def check_status
    video_id = params[:id]
    Rails.logger.debug "CHECK_STATUS: Starting check for video #{video_id}"

    cache_service = Cache::FileCacheService.new(Chat::ChatGptService.cache_namespace)
    result = cache_service.exist?(video_id) ? cache_service.read(video_id) : nil

    respond_to do |format|
      format.json do
        response_data = if result
          if result[:success]
            {
              status: "completed",
              summary: result
            }
          else
            {
              status: "failed",
              error: result[:error]
            }
          end
        else
          {
            status: "processing"
          }
        end

        render json: response_data
      end

      format.turbo_stream do
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

        partial_name = case params[:frame_id]
        when "summary"
          "summary_detail_section"
        else
          "#{params[:frame_id]}_section"
        end

        render turbo_stream: turbo_stream.update(
          params[:frame_id],
          partial: partial_name,
          locals: { summary: summary_data }
        )
      end
    end
  end

  def ask_gpt
    video_id = params[:id]
    question = params[:question]

    transcript_result = Youtube::YoutubeVideoTranscriptService.fetch_transcript(video_id)
    metadata = Youtube::YoutubeVideoMetadataService.fetch_metadata(video_id)

    if transcript_result[:success] && metadata[:success]
      result = Chat::ChatGptService.answer_question(video_id, question, transcript_result[:transcript_full], metadata)

      if result[:success]
        render json: { success: true, answer: result[:answer] }
      else
        render json: { success: false, error: result[:error] }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "Could not load video transcript" }, status: :unprocessable_entity
    end
  end

  private

  def extract_video_id(url)
    return nil unless url.present?

    if url.include?("youtu.be/")
      url.split("youtu.be/").last.split("?").first
    elsif url.include?("v=")
      url.split("v=").last.split("&").first
    end
  end
end
