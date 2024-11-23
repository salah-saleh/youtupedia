class SummariesController < ApplicationController
  def show
    video_id = extract_video_id(params[:youtube_url])
    transcript_result = YoutubeTranscriptService.fetch_transcript(video_id)

    if transcript_result["success"]
      if Rails.env.development?
        mock_response = JSON.parse(
          File.read(Rails.root.join("spec/fixtures/gpt_responses/health_podcast.json"))
        )

        @summary = {
          video_id: video_id,
          title: "Video Title",
          channel: "Channel Name",
          date: Time.now.strftime("%B %d, %Y"),
          time: "10:30",
          transcript: transcript_result["transcript"],
          tldr: mock_response["tldr"],
          takeaways: mock_response["takeaways"],
          tags: mock_response["tags"],
          summary: mock_response["summary"],
          rating: 4.5,
          votes: 123
        }
      else
        # Production code using ChatGPT
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
          summary: summary[:summary],
          rating: 4.5,
          votes: 123
        }
      end
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
