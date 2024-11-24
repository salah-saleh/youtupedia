class SummariesController < ApplicationController
  def show
    video_id = extract_video_id(params[:youtube_url])
    transcript_result = YoutubeTranscriptService.fetch_transcript(video_id)
    metadata_result = YoutubeMetadataService.fetch_metadata(video_id)

    if transcript_result[:success] && metadata_result[:success]
      summary_content = ChatGptService.generate_summary(video_id, transcript_result[:transcript_full])

      @summary = {
        video_id: video_id,
        title: metadata_result[:title],
        channel: metadata_result[:channel],
        date: metadata_result[:date],
        thumbnail: metadata_result[:thumbnail],
        description: metadata_result[:description],
        transcript: transcript_result[:transcript_segmented],
        tldr: summary_content[:tldr],
        takeaways: summary_content[:takeaways],
        tags: summary_content[:tags],
        summary: summary_content[:summary],
        rating: 4.5,
        votes: 123
      }
    else
      error_message = transcript_result[:success] ?
        metadata_result[:error] :
        "Could not fetch video transcript"
      redirect_to root_path, alert: error_message
    end
  end

  private

  def extract_video_id(url)
    url.split("v=").last
  end
end
