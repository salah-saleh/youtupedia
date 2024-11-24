class YoutubeTranscriptService
  CACHE_DIR = Rails.root.join("tmp/transcripts")

  def self.fetch_transcript(video_id)
    # Create cache directory if it doesn't exist
    FileUtils.mkdir_p(CACHE_DIR) unless Dir.exist?(CACHE_DIR)
    cache_file = CACHE_DIR.join("#{video_id}.json")

    if File.exist?(cache_file)
      Rails.logger.debug("Loading transcript from cache for video_id: #{video_id}")
      JSON.parse(File.read(cache_file))
    else
      Rails.logger.debug("Fetching new transcript for video_id: #{video_id}")
      fetch_and_cache_transcript(video_id, cache_file)
    end
  rescue => e
    Rails.logger.error "Transcript Error: #{e.message}"
    { "success" => false, "error" => e.message }
  end

  private

  def self.fetch_and_cache_transcript(video_id, cache_file)
    python_path = Rails.root.join("venv/bin/python")
    script_path = Rails.root.join("lib/python/youtube_transcript.py")

    Rails.logger.debug("Executing Python script with video_id: #{video_id}")
    output = `#{python_path} #{script_path} #{video_id}`

    # Parse and validate output before caching
    result = JSON.parse(output)

    if result["success"]
      Rails.logger.debug("Caching transcript for video_id: #{video_id}")
      File.write(cache_file, output)
    end

    result
  end
end
