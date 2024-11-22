class SummariesController < ApplicationController
  def show
    video_id = extract_video_id(params[:youtube_url])
    transcript_result = YoutubeTranscriptService.fetch_transcript(video_id)

    if transcript_result["success"]
      @summary = {
        video_id: video_id,
        title: "Video Title", # You might want to fetch this from YouTube API
        channel: "Channel Name",
        date: Time.now.strftime("%B %d, %Y"),
        time: "10:30",
        rating: 4.5,
        votes: 123,
        tldr: generate_tldr(transcript_result["transcript"]),
        takeaways: generate_takeaways(transcript_result["transcript"]),
        tags: [ "AI", "Technology", "Education" ],
        transcript: transcript_result["transcript"]
      }
    else
      flash[:error] = transcript_result["error"]
      redirect_to root_path
    end
  end

  private

  def extract_video_id(url)
    url.split("v=").last
  end

  def generate_tldr(transcript)
    transcript.first(3).map { |segment| segment["text"] }.join(" ")
  end

  def generate_takeaways(transcript)
    # You could implement AI key points extraction here
    [
      "Key point 1 from the video",
      "Key point 2 from the video",
      "Key point 3 from the video"
    ]
  end
end
