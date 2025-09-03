# Audio controller for serving generated TTS audio files
#
# This controller handles serving audio files from both temporary cache
# (for immediate streaming) and Active Storage (for permanent access).
class AudioController < ApplicationController
  include AudioResponseHandler
  
  # Input validation for audio ID
  before_action :validate_audio_id_before_show, only: [:show, :temp]
  
  # Serve audio file by ID via Active Storage redirect or temporary cache
  def show
    audio_id = params[:id]
    
    log_info "Serving audio file", context: { audio_id: audio_id }
    
    begin
      # Fetch audio metadata from TTS service storage
      audio_data = Ai::TtsService.fetch_audio(audio_id)
      
      unless audio_data&.dig(:success)
        log_warn "Audio not found for ID: #{audio_id}"
        render_audio_error("Audio file not found")
        return
      end
      
      # Check if this is temporary storage or permanent storage
      if audio_data[:temp_storage]
        # Redirect to temporary streaming endpoint
        redirect_to audio_temp_path(audio_id), allow_other_host: false
        return
      end
      
      # Check if we have a blob_id for Active Storage (permanent)
      unless audio_data[:blob_id].present?
        log_error "Audio blob ID is missing for audio ID: #{audio_id}", context: { 
          audio_data_keys: audio_data.keys,
          has_success: audio_data[:success]
        }
        render_audio_error("Audio content not available")
        return
      end
      
      # Find the Active Storage blob
      begin
        blob = ActiveStorage::Blob.find(audio_data[:blob_id])
        
        log_info "Redirecting to Active Storage blob", context: {
          audio_id: audio_id,
          blob_id: blob.id,
          blob_key: blob.key,
          filename: blob.filename.to_s,
          content_type: blob.content_type,
          byte_size: blob.byte_size
        }
        
        # Redirect to Active Storage URL (serves from GCS in production, local in development)
        redirect_to rails_blob_path(blob, disposition: 'inline'), allow_other_host: false
        
      rescue ActiveRecord::RecordNotFound
        log_error "Audio blob not found for audio ID: #{audio_id}", context: { 
          blob_id: audio_data[:blob_id] 
        }
        render_audio_error("Audio file not found")
      end
      
    rescue => e
      log_error "Error serving audio file", context: { 
        audio_id: audio_id, 
        error: e.message 
      }
      render_audio_error("Error loading audio file")
    end
  end
  
  # Serve audio from temporary cache for immediate streaming
  def temp
    audio_id = params[:id]
    
    log_info "Serving temporary audio file", context: { audio_id: audio_id }
    
    begin
      # Get from temporary cache
      cache_key = "temp_audio:#{audio_id}"
      cached_data = Rails.cache.read(cache_key)
      
      unless cached_data
        log_warn "Temporary audio not found for ID: #{audio_id}"
        
        # Check if permanent version is available
        audio_data = Ai::TtsService.fetch_audio(audio_id)
        if audio_data&.dig(:success) && audio_data[:blob_id]
          # Redirect to permanent version
          redirect_to audio_path(audio_id), allow_other_host: false
          return
        end
        
        render_audio_error("Temporary audio file not found or expired")
        return
      end
      
      # Serve the cached audio data directly
      audio_content = cached_data[:audio_data]
      mime_type = cached_data[:mime_type]
      
      log_info "Serving temporary audio content", context: {
        audio_id: audio_id,
        mime_type: mime_type,
        content_size_mb: (audio_content.length / 1024.0 / 1024.0).round(2)
      }
      
      serve_audio_content(audio_content, audio_id, mime_type: mime_type)
      
    rescue => e
      log_error "Error serving temporary audio file", context: { 
        audio_id: audio_id, 
        error: e.message 
      }
      render_audio_error("Error loading temporary audio file")
    end
  end
  
  private
  
  # Validate audio ID parameter using the concern method
  def validate_audio_id_before_show
    validate_audio_id_param(params[:id])
  end
end
