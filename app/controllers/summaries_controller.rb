class SummariesController < ApplicationController
  include SummaryLoader
  layout "dashboard"

  def create_from_url
    video_id = extract_video_id(params[:youtube_url])
    return redirect_to root_path, alert: "Invalid YouTube URL" unless video_id

    # Redirect to show page, which will handle the summary creation if needed
    redirect_to summary_path(id: video_id)
  end

  def show
    @video_id = params[:id]
    cache_service = Cache::FileCacheService.new(ChatGptService.cache_namespace)

    # If summary exists in cache, load it
    if cache_service.exist?(@video_id)
      result = cache_service.read(@video_id)
      if result[:success]
        @summary = {
          video_id: @video_id,
          loading: false
        }.merge(result)
        return
      end
    end

    # If we get here, either there's no summary or it failed
    # Let's try to create it
    @metadata = YoutubeMetadataService.fetch_metadata(@video_id)
    return redirect_to root_path, alert: @metadata[:error] unless @metadata[:success]

    @transcript = YoutubeTranscriptService.fetch_transcript(@video_id)
    return redirect_to root_path, alert: @transcript[:error] unless @transcript[:success]

    # Schedule the summary generation
    ChatGptService.process_async(@video_id, @transcript[:transcript_full])

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

  def check_status
    video_id = params[:id]
    Rails.logger.debug "CHECK_STATUS: Starting check for video #{video_id}"

    cache_service = Cache::FileCacheService.new(ChatGptService.cache_namespace)
    Rails.logger.debug "CHECK_STATUS: Created cache service for '#{ChatGptService.cache_namespace}' namespace"

    if cache_service.exist?(video_id)
      Rails.logger.debug "CHECK_STATUS: Cache file exists, attempting to read"
      result = cache_service.read(video_id)
      Rails.logger.debug "CHECK_STATUS: Read result from cache: #{result.inspect.first(100)}"
    else
      Rails.logger.debug "CHECK_STATUS: Cache file does not exist"
      result = nil
    end

    respond_to do |format|
      # JSON response for status check
      format.json do
        response_data = if result && result[:success]
          Rails.logger.debug "CHECK_STATUS: Found successful result in cache"
          {
            status: "completed",
            summary: result
          }
        else
          Rails.logger.debug "CHECK_STATUS: No successful result in cache yet"
          {
            status: "processing"
          }
        end

        Rails.logger.debug "CHECK_STATUS: Sending JSON response: #{response_data.inspect}"
        render json: response_data
      end

      # Turbo Stream response for section updates
      format.turbo_stream do
        summary_data = if result && result[:success]
          Rails.logger.debug "CHECK_STATUS: Preparing successful Turbo Stream response"
          result.merge(loading: false)
        else
          Rails.logger.debug "CHECK_STATUS: Preparing loading Turbo Stream response"
          {
            loading: true,
            tldr: "",
            takeaways: [],
            tags: [],
            summary: ""
          }
        end

        Rails.logger.debug "CHECK_STATUS: Frame ID: #{params[:frame_id]}"
        Rails.logger.debug "CHECK_STATUS: Summary data for Turbo Stream: #{summary_data.inspect}"

        partial_name = case params[:frame_id]
        when "summary"
          "summary_detail_section"
        else
          "#{params[:frame_id]}_section"
        end

        Rails.logger.debug "CHECK_STATUS: Rendering Turbo Stream with partial: #{partial_name}"
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

    transcript_result = YoutubeTranscriptService.fetch_transcript(video_id)

    if transcript_result[:success]
      result = ChatGptService.answer_question(video_id, question, transcript_result[:transcript_full])

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
