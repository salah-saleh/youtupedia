module Youtube
  class YoutubeVideoTranscriptService < YoutubeBaseService
    def self.fetch_transcript(video_id)
      segmented_result = fetch_cached(video_id, "transcripts/segmented") do
        fetch_from_python(video_id)
      end

      return segmented_result unless segmented_result[:success]

      full_result = fetch_cached(video_id, "transcripts/full") do
        create_full_transcript(segmented_result[:transcript])
      end

      {
        success: true,
        transcript_segmented: segmented_result[:transcript],
        transcript_full: full_result[:transcript]
      }
    rescue => e
      handle_error(e, "Transcript Error")
    end

    private

    def self.fetch_from_python(video_id)
      python_path = determine_python_path
      script_path = Rails.root.join("lib/python/youtube_transcript.py")

      Rails.logger.debug("Executing Python script with video_id: #{video_id}")
      output = `#{python_path} #{script_path} #{video_id}`

      JSON.parse(output, symbolize_names: true)
    end

    def self.create_full_transcript(segmented_transcript)
      full_text = segmented_transcript.map do |entry|
        "#{entry[:text]} (#{entry[:start]})"
      end.join(" ")

      {
        success: true,
        transcript: full_text
      }
    end

    def self.determine_python_path
      if Rails.env.production?
        "/app/.heroku/python/bin/python"
      else
        Rails.root.join("venv/bin/python")
      end
    end
  end
end
