# Text-to-Speech service using Gemini 2.5 Pro Preview TTS via Python client
#
# This service converts text summaries to audio using Google's Gemini TTS API.
# It leverages the existing Python-based Gemini infrastructure for consistency
# and proper handling of encoding, timeouts, and error management.
#
# Responsibilities:
# 1) Convert text summaries to audio using Gemini TTS Python client
# 2) Store audio files in Google Cloud Storage via Active Storage
# 3) Store metadata in MongoDB (without audio content)
# 4) Handle audio formats and streaming
# 5) Provide progress updates via Turbo Streams
module Ai
  class TtsService < BaseService
    include Persistable
    include PythonScriptable

    # Default voice selection - using Algenib voice (as per Gemini TTS API example)
    DEFAULT_VOICE = "Algenib"

    def initialize(voice = DEFAULT_VOICE)
      @voice = voice
    end

    class << self
      # Fetch stored TTS audio data for a video
      def fetch_audio(video_id, reset_on_failed: false)
        result = read_stored(video_id)
        if reset_on_failed && result&.dig(:success) == false
          delete_stored(video_id)
          return nil
        end
        
        # If we have a blob_id, verify the blob still exists
        if result&.dig(:success) && result[:blob_id]
          begin
            blob = ActiveStorage::Blob.find(result[:blob_id])
            # Update URL in case it changed (e.g., after deployment)
            result[:audio_url] = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
          rescue ActiveRecord::RecordNotFound
            log_warn "Audio blob not found for video #{video_id}, blob_id: #{result[:blob_id]}"
            # Clean up the orphaned metadata
            delete_stored(video_id)
            return nil
          end
        end
        
        result
      end

      # Check if audio exists for a video
      def audio_exists?(video_id)
        stored?(video_id) && fetch_audio(video_id)&.dig(:success)
      end
    end

    # Generate audio from text summary using Python TTS client
    def generate_audio(video_id, text, voice = nil)
      @voice = voice if voice
      
      log_info "Starting TTS generation for video #{video_id}", context: { voice: @voice, text_length: text.length }
      
      # Check if we already have audio for this video
      existing_audio = self.class.fetch_audio(video_id)
      if existing_audio&.dig(:success)
        log_info "Audio already exists for video #{video_id}"
        return existing_audio
      end

      # Prepare input data for Python TTS client
      input_data = {
        text: text,
        voice_name: @voice,
        video_id: video_id
      }

      # Use Python TTS client with proper timeout for audio generation
      tts_timeout = ENV.fetch("TTS_TIMEOUT", 120).to_i
      start_time = Time.current
      
      log_info "Calling Python TTS client", context: { 
        video_id: video_id, 
        voice: @voice, 
        timeout: tts_timeout,
        text_length: text.length 
      }
      
      result = run_python_script("gemini_tts_client.py", input_data, timeout: tts_timeout)
      
      if result[:success]
        # Create Active Storage blob for audio file
        audio_blob = create_audio_blob(video_id, result[:audio_content], result[:mime_type] || "audio/wav")
        
        # Build audio data with Active Storage URL and metadata (no audio_content in MongoDB)
        audio_data = {
          success: true,
          audio_url: Rails.application.routes.url_helpers.rails_blob_path(audio_blob, only_path: true),
          blob_id: audio_blob.id,
          voice: result[:voice] || @voice,
          text_length: result[:text_length] || text.length,
          generated_at: Time.current,
          duration_seconds: result[:duration_seconds] || 0,
          mime_type: result[:mime_type] || "audio/wav",
          data_size: result[:data_size] || 0,
          # Token usage tracking for cost analysis
          token_usage: result[:token_usage] || {},
          model: result[:model] || "gemini-2.5-flash-preview-tts",
          config: result[:config] || {}
        }
        
        self.class.write_stored(video_id, audio_data)
        
        elapsed_time = (Time.current - start_time).round(2)
        
        # Enhanced logging with token usage information
        log_context = { 
          duration: audio_data[:duration_seconds],
          elapsed_seconds: elapsed_time,
          data_size_mb: (audio_data[:data_size] / 1024.0 / 1024.0).round(2),
          voice: audio_data[:voice],
          model: audio_data[:model]
        }
        
        # Add token usage to log context if available
        if result[:token_usage]
          log_context.merge!({
            input_tokens: result[:token_usage][:input_tokens],
            processing_tokens: result[:token_usage][:processing_tokens],
            total_tokens: result[:token_usage][:total_tokens],
            estimation_method: result[:token_usage][:estimation_method]
          })
        end
        
        log_info "TTS generation completed for video #{video_id}", context: log_context
        
        audio_data
      else
        # Store the error for caching
        error_data = {
          success: false,
          error: result[:error],
          attempted_at: Time.current
        }
        self.class.write_stored(video_id, error_data)
        
        elapsed_time = (Time.current - start_time).round(2)
        log_error "TTS generation failed for video #{video_id}", context: { 
          error: result[:error],
          elapsed_seconds: elapsed_time
        }
        result
      end
    end

    private

    # Creates an Active Storage blob for audio content
    # @param video_id [String] Video ID for filename
    # @param base64_content [String] Base64 encoded audio content
    # @param mime_type [String] MIME type of the audio
    # @return [ActiveStorage::Blob] Created blob
    def create_audio_blob(video_id, base64_content, mime_type)
      # Decode base64 content to binary
      audio_data = Base64.strict_decode64(base64_content)
      
      # Generate filename with appropriate extension
      file_extension = case mime_type
                      when /wav/ then "wav"
                      when /mp3/ then "mp3"
                      when /mpeg/ then "mp3"
                      when /ogg/ then "ogg"
                      else "wav"
                      end
      
      filename = "#{video_id}.#{file_extension}"
      
      log_info "Creating Active Storage blob for audio", context: {
        video_id: video_id,
        filename: filename,
        mime_type: mime_type,
        data_size_mb: (audio_data.length / 1024.0 / 1024.0).round(2)
      }
      
      # Create and upload blob to configured storage service (GCS in production, local in development)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(audio_data),
        filename: filename,
        content_type: mime_type,
        metadata: {
          video_id: video_id,
          generated_at: Time.current.iso8601,
          service: "tts_generation"
        }
      )
      
      log_info "Successfully created audio blob", context: {
        video_id: video_id,
        blob_id: blob.id,
        blob_key: blob.key,
        filename: filename
      }
      
      blob
    rescue => e
      log_error "Failed to create audio blob", context: {
        video_id: video_id,
        error: e.message,
        mime_type: mime_type
      }
      raise
    end

  end
end
