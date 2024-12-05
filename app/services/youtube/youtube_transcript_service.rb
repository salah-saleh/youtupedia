module Youtube
  class YoutubeTranscriptService
    def self.fetch_transcript(video_id)
      segmented_cache = Cache::FileCacheService.new("transcripts/segmented")
      full_cache = Cache::FileCacheService.new("transcripts/full")

      segmented_result = segmented_cache.fetch(video_id) do
        fetch_from_python(video_id)
      end

      return segmented_result unless segmented_result[:success]

      full_result = full_cache.fetch(video_id) do
        create_full_transcript(segmented_result[:transcript])
      end

      {
        success: true,
        transcript_segmented: segmented_result[:transcript],
        transcript_full: full_result[:transcript]
      }
    rescue => e
      Rails.logger.error "Transcript Error: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def self.fetch_from_python(video_id)
      # Use the system Python path on Heroku, fallback to venv for local development
      python_path = if Rails.env.production?
        "/usr/local/bin/python"
      else
        Rails.root.join("venv/bin/python")
      end
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
  end
end
