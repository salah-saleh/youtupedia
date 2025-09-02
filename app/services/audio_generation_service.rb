# frozen_string_literal: true

# AudioGenerationService handles the business logic for generating audio summaries
# from text content using the TTS service.
#
# This service encapsulates:
# - Summary validation and preparation
# - Audio generation coordination with TTS service
# - Job scheduling for background processing
# - Error handling and logging
#
# Usage:
#   service = AudioGenerationService.new(video_id, voice)
#   result = service.generate_or_schedule_audio
#
class AudioGenerationService < BaseService
  
  # Default voice for TTS generation
  DEFAULT_VOICE = "Algenib"
  
  # Initialize the audio generation service
  # @param video_id [String] The video ID to generate audio for
  # @param voice [String] The voice to use for TTS (default: Algenib)
  def initialize(video_id, voice = DEFAULT_VOICE)
    @video_id = video_id
    @voice = voice
  end

  # Main method to generate or schedule audio generation
  # Checks for existing audio, validates summary availability,
  # and either returns existing audio or schedules generation
  #
  # @return [Hash] Result hash with success status and data/error information
  def generate_or_schedule_audio
    log_info "Audio generation requested", context: { 
      video_id: @video_id, 
      voice: @voice
    }

    # Check if audio already exists
    existing_result = check_existing_audio
    return existing_result if existing_result

    # Validate summary availability
    summary_result = validate_summary_availability
    return summary_result unless summary_result[:success]

    # Schedule the audio generation job
    schedule_audio_generation
  end

  private

  # Check if audio already exists for the video
  # @return [Hash, nil] Success result with audio data if exists, nil otherwise
  def check_existing_audio
    if Ai::TtsService.audio_exists?(@video_id)
      existing_audio = Ai::TtsService.fetch_audio(@video_id)
      if existing_audio&.dig(:success)
        log_info "Returning existing audio", context: { video_id: @video_id }
        
        return {
          success: true,
          type: :existing_audio,
          audio_data: existing_audio,
          message: "Audio summary is already available!"
        }
      end
    end
    nil
  end

  # Validate that a summary exists for the video
  # @return [Hash] Result hash indicating success or failure with error message
  def validate_summary_availability
    summary = Ai::LlmSummaryService.fetch_summary(@video_id)
    unless summary&.dig(:success)
      log_info "No summary available for audio generation", context: { video_id: @video_id }
      
      return {
        success: false,
        error: "No summary available for this video. Please wait for the summary to complete first."
      }
    end
    
    { success: true, summary: summary }
  end

  # Schedule the audio generation background job
  # @return [Hash] Result hash indicating job scheduling success or failure
  def schedule_audio_generation
    begin
      if AudioSummaryJob.schedule(@video_id, @voice)
        log_info "Audio generation job scheduled", context: { video_id: @video_id, voice: @voice }
        
        {
          success: true,
          type: :job_scheduled,
          message: "Audio generation started! This may take a few minutes."
        }
      else
        log_info "Audio generation job already running", context: { video_id: @video_id, voice: @voice }
        
        {
          success: true,
          type: :job_already_running,
          message: "Audio generation is already in progress. Please wait..."
        }
      end
    rescue => e
      log_error "Failed to schedule audio generation job", context: { 
        video_id: @video_id,
        error: e.message,
        backtrace: e.backtrace.first(3)
      }
      
      {
        success: false,
        error: "Failed to start audio generation. Please try again."
      }
    end
  end
end
