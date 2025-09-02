# Text-to-Speech service using Gemini 2.5 Pro Preview TTS via Python client
#
# This service converts text summaries to audio using Google's Gemini TTS API.
# It leverages the existing Python-based Gemini infrastructure for consistency
# and proper handling of encoding, timeouts, and error management.
#
# Responsibilities:
# 1) Convert text summaries to audio using Gemini TTS Python client
# 2) Store audio files with proper metadata
# 3) Handle audio formats and streaming
# 4) Provide progress updates via Turbo Streams
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
        result
      end

      # Check if audio exists for a video
      def audio_exists?(video_id)
        stored?(video_id)
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
        # Build audio data with URL and metadata
        audio_data = {
          success: true,
          audio_url: "/audio/#{video_id}",
          voice: result[:voice] || @voice,
          text_length: result[:text_length] || text.length,
          generated_at: Time.current,
          duration_seconds: result[:duration_seconds] || 0,
          mime_type: result[:mime_type] || "audio/wav",
          data_size: result[:data_size] || 0,
          audio_content: result[:audio_content],  # Base64 encoded WAV audio
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

  end
end
