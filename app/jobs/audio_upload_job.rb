# Background job to upload audio files to Google Cloud Storage
# and update metadata after temporary storage has been created
#
# This job runs after TTS generation is complete and audio is
# temporarily available for streaming, ensuring users can start
# listening immediately while the permanent upload happens in background.
class AudioUploadJob < ApplicationJob
  queue_as :default
  
  # Override job logging to prevent base64 audio content from corrupting logs
  def self.log_arguments?
    false
  end
  
  def perform(video_id, base64_audio_content, mime_type)
    log_info "Starting async audio upload for video #{video_id}"
    
    begin
      # Create Active Storage blob for permanent storage
      tts_service = Ai::TtsService.new
      audio_blob = tts_service.send(:create_audio_blob, video_id, base64_audio_content, mime_type)
      
      # Update stored metadata with blob information
      existing_data = Ai::TtsService.fetch_audio(video_id)
      if existing_data&.dig(:success)
        # Update with permanent storage info
        updated_data = existing_data.merge({
          audio_url: Rails.application.routes.url_helpers.rails_blob_path(audio_blob, only_path: true),
          blob_id: audio_blob.id,
          temp_storage: false, # No longer temporary
          uploaded_at: Time.current
        })
        
        Ai::TtsService.write_stored(video_id, updated_data)
        
        # Clean up temporary cache
        Rails.cache.delete("temp_audio:#{video_id}")
        
        # Broadcast updated audio player with permanent URL
        # broadcast_audio_update(video_id, updated_data)
        
        log_info "Audio upload completed for video #{video_id}", context: {
          blob_id: audio_blob.id,
          blob_key: audio_blob.key
        }
      else
        log_error "No existing audio data found during upload", context: { video_id: video_id }
      end
      
    rescue => e
      log_error "Audio upload failed for video #{video_id}", context: {
        error: e.message,
        backtrace: e.backtrace.first(3)
      }
      
      # Mark upload as failed but keep temporary storage
      existing_data = Ai::TtsService.fetch_audio(video_id)
      if existing_data&.dig(:success)
        failed_data = existing_data.merge({
          upload_failed: true,
          upload_error: e.message,
          upload_attempted_at: Time.current
        })
        Ai::TtsService.write_stored(video_id, failed_data)
      end
    end
  end
end