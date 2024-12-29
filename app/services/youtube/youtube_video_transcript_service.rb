module Youtube
  # Service for fetching and processing YouTube video transcripts
  # Uses Python script for transcript extraction and provides both segmented and full versions
  class YoutubeVideoTranscriptService < YoutubeBaseService
    include AsyncProcessable
    include Cacheable

    class << self
      def fetch_transcript(video_id)
        fetch_cached(video_id, namespace: default_cache_namespace, expires_in: nil)
      end
    end

    def process_task(video_id)
      begin
        # Get segmented transcript from Python
        segmented_result = self.class.fetch_from_python(video_id)

        unless segmented_result[:success]
          return {
            success: false,
            error: segmented_result[:error]
          }
        end

        # Create full transcript
        full_result = self.class.create_full_transcript(segmented_result[:transcript])

        {
          success: true,
          transcript_segmented: segmented_result[:transcript],
          transcript_full: full_result[:transcript]
        }
      rescue => e
        handle_error(e, "Transcript Error")
      end
    end

    private

    # Executes Python script to fetch raw transcript data
    # @param video_id [String] YouTube video ID
    # @return [Hash] Raw transcript data from YouTube
    def self.fetch_from_python(video_id)
      python_path = determine_python_path
      script_path = Rails.root.join("lib/python/youtube_transcript.py")

      log_info "Executing Python script", context: { video_id: video_id }
      output = `#{python_path} #{script_path} #{video_id}`

      JSON.parse(output, symbolize_names: true)
    end

    # Combines segmented transcript into a single text with timestamps
    # @param segmented_transcript [Array<Hash>] Time-stamped transcript segments
    # @return [Hash] Full transcript with success status
    def self.create_full_transcript(segmented_transcript)
      full_text = segmented_transcript.map do |entry|
        "#{entry[:text]} (#{entry[:start]})"
      end.join(" ")

      {
        success: true,
        transcript: full_text
      }
    end

    # Determines Python interpreter path based on environment
    # @return [String] Path to Python interpreter
    def self.determine_python_path
      ENV["PYTHON_PATH"]
    end
  end
end
