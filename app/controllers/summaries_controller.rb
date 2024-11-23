class SummariesController < ApplicationController
  def show
    video_id = extract_video_id(params[:youtube_url])
    transcript_result = YoutubeTranscriptService.fetch_transcript(video_id)

    if transcript_result["success"]
      summary = ChatGptService.generate_summary(transcript_result["transcript"])

      @summary = {
        video_id: video_id,
        title: "Video Title", # You might want to fetch this from YouTube API
        channel: "Channel Name",
        date: Time.now.strftime("%B %d, %Y"),
        time: "10:30",
        transcript: transcript_result["transcript"],
        tldr: summary[:tldr],
        takeaways: summary[:takeaways],
        tags: summary[:tags],
        rating: 4.5,
        votes: 123
      }
    else
      # Handle error
      redirect_to root_path, alert: "Could not fetch video transcript"
    end
  end

  private

  def extract_video_id(url)
    url.split("v=").last
  end
end
