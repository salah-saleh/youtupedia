class YoutubeTranscriptService
  CACHE_DIR = Rails.root.join("tmp/transcripts")
  SEGMENTED_SUFFIX = "_segmented.json"
  FULL_SUFFIX = "_full.json"

  def self.fetch_transcript(video_id)
    # Create cache directory if it doesn't exist
    FileUtils.mkdir_p(CACHE_DIR) unless Dir.exist?(CACHE_DIR)

    segmented_cache_file = CACHE_DIR.join("#{video_id}#{SEGMENTED_SUFFIX}")
    full_cache_file = CACHE_DIR.join("#{video_id}#{FULL_SUFFIX}")

    if File.exist?(segmented_cache_file) && File.exist?(full_cache_file)
      Rails.logger.debug("Loading transcript from cache for video_id: #{video_id}")
      segmented_result = JSON.parse(File.read(segmented_cache_file), symbolize_names: true)
      full_result = JSON.parse(File.read(full_cache_file), symbolize_names: true)

      {
        success: true,
        transcript_segmented: segmented_result[:transcript],
        transcript_full: full_result[:transcript]
      }
    else
      Rails.logger.debug("Fetching new transcript for video_id: #{video_id}")
      fetch_and_cache_transcript(video_id, segmented_cache_file, full_cache_file)
    end
  rescue => e
    Rails.logger.error "Transcript Error: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def self.fetch_and_cache_transcript(video_id, segmented_cache_file, full_cache_file)
    python_path = Rails.root.join("venv/bin/python")
    script_path = Rails.root.join("lib/python/youtube_transcript.py")

    Rails.logger.debug("Executing Python script with video_id: #{video_id}")
    output = `#{python_path} #{script_path} #{video_id}`

    # Parse and validate output before caching
    result = JSON.parse(output, symbolize_names: true)

    if result[:success]
      # Cache segmented transcript
      Rails.logger.debug("Caching segmented transcript for video_id: #{video_id}")
      File.write(segmented_cache_file, output)

      # Create and cache the full text version
      full_text = result[:transcript].map { |entry| entry["text"] }.join(" ")
      full_version = {
        success: true,
        transcript: full_text
      }

      Rails.logger.debug("Caching full transcript for video_id: #{video_id}")
      File.write(full_cache_file, full_version.to_json)

      # Return combined result
      {
        success: true,
        transcript_segmented: result[:transcript],
        transcript_full: full_text
      }
    else
      result
    end
  end
end
