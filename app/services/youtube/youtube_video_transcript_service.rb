module Youtube
  # Service for fetching and processing YouTube video transcripts
  # Uses Python script for transcript extraction and provides both segmented and full versions
  class YoutubeVideoTranscriptService < YoutubeBaseService
    include PythonScriptable
    include Persistable

    class << self
      def fetch_transcript(video_id, retry_on_failed: false)
        result = read_stored(video_id)
        if retry_on_failed && result&.dig(:success) == false
          delete_stored(video_id)
          return nil
        end
        result
      end

      def fetch_from_python(video_id)
        # Use a shorter timeout specifically for transcript fetching to prevent hanging
        # YouTube transcript API can sometimes hang indefinitely
        transcript_timeout = ENV.fetch("YOUTUBE_TRANSCRIPT_TIMEOUT", 8).to_i
        run_python_script("youtube_transcript.py", { video_id: video_id }, timeout: transcript_timeout)
      end

      # Combines segmented transcript into a single text with timestamps
      # @param segmented_transcript [Array<Hash>] Time-stamped transcript segments
      # @return [Hash] Full transcript with success status
      def create_full_transcript(segmented_transcript)
        full_text = segmented_transcript.map do |entry|
          "#{entry[:text]} (#{entry[:start]})"
        end.join(" ")

        {
          success: true,
          transcript: full_text
        }
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
        handle_youtube_error(e)
      end
    end
  end
end
