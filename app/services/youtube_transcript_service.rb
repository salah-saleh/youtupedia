class YoutubeTranscriptService
  def self.fetch_transcript(video_id)
    python_path = Rails.root.join("venv/bin/python")
    script_path = Rails.root.join("lib/python/youtube_transcript.py")
    Rails.logger.debug("Executing Python script with video_id: #{video_id}")
    output = `#{python_path} #{script_path} #{video_id}`
    Rails.logger.debug("Python script output")
    JSON.parse(output)
  rescue => e
    Rails.logger.error "Transcript Error: #{e.message}"
    { "success" => false, "error" => e.message }
  end
end
