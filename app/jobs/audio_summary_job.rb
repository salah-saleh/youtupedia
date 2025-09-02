# Handles generating audio summaries from text summaries using Gemini TTS
#
# Responsibilities:
# 1) Fetch the existing text summary for a video
# 2) Generate audio using the TTS service
# 3) Store the audio result
# 4) Push UI updates via Turbo Streams to show the audio player
# 5) Handle errors gracefully and provide user feedback
#
# The job is safe to schedule multiple times; each step is idempotent through caching.
class AudioSummaryJob < ApplicationJob
  include JobSchedulable
  include TimeHelper  # Include the helper for format_duration
  
  queue_as :default

  def perform(video_id, voice = "Algenib")
    log_info "Starting audio summary job for video #{video_id}", context: { voice: voice }
    
    # Fetch the existing summary data
    summary = Ai::LlmSummaryService.fetch_summary(video_id)
    unless summary&.dig(:success)
      log_error "No summary found for video #{video_id}"
      update_audio_section(video_id, { success: false, error: "No summary available for this video" })
      return
    end

    # Extract the summary text for TTS generation
    summary_text = summary[:summary]
    unless summary_text && summary_text.length > 50
      log_error "Summary text too short for TTS generation", context: { text_length: summary_text&.length }
      update_audio_section(video_id, { success: false, error: "Summary text is too short for audio generation" })
      return
    end

    # Generate audio using the TTS service
    log_info "Generating audio for video #{video_id}", context: { text_length: summary_text.length }
    tts_service = Ai::TtsService.new(voice)
    result = tts_service.generate_audio(video_id, summary_text, voice)

    # Update the UI with the result
    update_audio_section(video_id, result)
    
    if result[:success]
      log_info "Audio summary job completed for video #{video_id}", context: { duration: result[:duration_seconds] }
    else
      log_error "Audio summary job failed for video #{video_id}", context: { error: result[:error] }
    end
  end

  private

  # Update the audio section in the UI via Turbo Streams
  def update_audio_section(video_id, result)
    log_info "Updating audio section for video #{video_id}"
    
    # Push server-rendered Turbo Stream directly to the stream identified in the view
    Turbo::StreamsChannel.broadcast_replace_to(
      "summaries:#{video_id}",
      target: "audio_summary",
      partial: "summaries/show/audio_summary_section",
      locals: { 
        audio_data: result, 
        video_id: video_id
      }
    )
    
    # Also send a stream to reset the button state via JavaScript
    Turbo::StreamsChannel.broadcast_action_to(
      "summaries:#{video_id}",
      action: "invoke",
      target: "audio_summary",
      method: "resetGeneratingState"
    )
  end
  
end
