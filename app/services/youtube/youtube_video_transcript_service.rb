module Youtube
  # Service for fetching and processing YouTube video transcripts
  # Uses Python script for transcript extraction and provides both segmented and full versions
  class YoutubeVideoTranscriptService < YoutubeBaseService
    include AsyncProcessable
    include Cacheable
    include PythonScriptable

    class << self
      def fetch_transcript(video_id)
        fetch_cached(video_id, namespace: default_cache_namespace, expires_in: nil)
      end

      def fetch_from_python(video_id)
        run_python_script("youtube_transcript.py", { video_id: video_id })
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
