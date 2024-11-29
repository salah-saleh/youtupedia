class SummariesController < ApplicationController
  include SummaryLoader
  layout "dashboard"

  def show
    video_id = extract_video_id(params[:youtube_url])
    return redirect_to root_path, alert: "Invalid YouTube URL" unless video_id

    @metadata = YoutubeMetadataService.fetch_metadata(video_id)
    return redirect_to root_path, alert: @metadata[:error] unless @metadata[:success]

    @transcript = YoutubeTranscriptService.fetch_transcript(video_id)
    return redirect_to root_path, alert: @transcript[:error] unless @transcript[:success]

    summary_content = ChatGptService.generate_summary(video_id, @transcript[:transcript_full])
    return redirect_to root_path, alert: summary_content[:error] unless summary_content[:success]

    @summary = {
      video_id: video_id,
      title: @metadata.dig(:metadata, :title),
      channel: @metadata.dig(:metadata, :channel_title),
      date: @metadata.dig(:metadata, :published_at),
      thumbnail: @metadata.dig(:metadata, :thumbnails, :high),
      description: @metadata.dig(:metadata, :description),
      transcript: @transcript[:transcript_segmented],
      tldr: summary_content[:tldr],
      takeaways: summary_content[:takeaways],
      tags: summary_content[:tags],
      summary: summary_content[:summary],
      rating: 4.5, # Mock data
      votes: 123  # Mock data
    }
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
