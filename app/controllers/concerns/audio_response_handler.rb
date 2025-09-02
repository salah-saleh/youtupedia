# frozen_string_literal: true

# AudioResponseHandler provides standardized audio-related response handling
# for controllers dealing with audio content and TTS functionality.
#
# This concern handles common patterns for:
# - Audio content validation and error responses
# - Turbo Stream responses for audio-related actions
# - Rate limiting for audio generation
# - Audio file serving with proper headers
#
# Usage:
#   class AudioController < ApplicationController
#     include AudioResponseHandler
#   end
#
module AudioResponseHandler
  extend ActiveSupport::Concern

  private

  # Validates audio ID parameter with comprehensive checks
  # @param audio_id [String] The audio ID to validate
  # @return [Boolean] true if valid, renders error response if invalid
  def validate_audio_id_param(audio_id = params[:id])
    if audio_id.blank?
      log_warn "Empty audio ID provided"
      render_audio_error("Audio ID is required")
      return false
    end

    # Basic format validation (YouTube video IDs are typically 11 characters alphanumeric with dashes/underscores)
    unless audio_id.match?(/\A[A-Za-z0-9_-]+\z/)
      log_warn "Invalid audio ID format", context: { audio_id: audio_id }
      render_audio_error("Invalid audio ID format")
      return false
    end

    # Length validation
    if audio_id.length > 50
      log_warn "Audio ID too long", context: { audio_id: audio_id, length: audio_id.length }
      render_audio_error("Audio ID too long")
      return false
    end

    true
  end

  # Validates video ID parameter for audio generation
  # @param video_id [String] The video ID to validate
  # @return [Boolean] true if valid, renders error response if invalid
  def validate_video_id_for_audio(video_id)
    unless video_id.present? && video_id.match?(/\A[A-Za-z0-9_-]+\z/)
      log_warn "Invalid video ID for audio generation", context: { video_id: video_id }
      render_audio_error("Invalid video ID provided.")
      return false
    end
    true
  end

  # Checks rate limiting for audio generation
  # @param user_id [String, nil] User ID for rate limiting
  # @param ip [String] IP address for rate limiting
  # @param limit [Integer] Maximum requests allowed (default: 5)
  # @param window [Integer] Time window in seconds (default: 300)
  # @return [Boolean] true if not rate limited, renders error response if limited
  def check_audio_rate_limit(user_id: Current.user&.id, ip: request.remote_ip, limit: 5, window: 300)
    rate_limit_key = "audio_generation:#{user_id || ip}"
    
    if rate_limited?(rate_limit_key, limit: limit, window: window)
      log_warn "Rate limit exceeded for audio generation", context: { 
        key: rate_limit_key,
        user_id: user_id,
        ip: ip
      }
      
      render_audio_error("Rate limit exceeded. Please wait before requesting another audio generation.")
      return false
    end
    
    true
  end

  # Renders standardized audio error responses with both Turbo Stream and HTML formats
  # @param message [String] Error message to display
  # @param target [String] DOM target for Turbo Stream updates (default: "audio-content")
  def render_audio_error(message, target: "audio-content")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(target,
          partial: "shared/error_message", 
          locals: { message: message })
      end
      format.html { redirect_to root_path, alert: message }
    end
  end

  # Renders audio generation success response with Turbo Streams
  # @param video_id [String] Video ID
  # @param audio_data [Hash] Audio data from TTS service
  # @param message [String] Success message
  def render_audio_success(video_id, audio_data, message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("audio_summary", 
            partial: "summaries/show/audio_summary_section",
            locals: { video_id: video_id, audio_data: audio_data }),
          turbo_stream.prepend("flash-messages", 
            partial: "shared/flash_message", 
            locals: { type: "success", message: message })
        ]
      end
      format.html { redirect_to summary_path(video_id), notice: message }
    end
  end

  # Renders audio generation in progress response with Turbo Streams
  # @param video_id [String] Video ID
  # @param message [String] Progress message
  # @param flash_type [String] Flash message type (default: "success")
  def render_audio_generating(video_id, message, flash_type: "success")
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("audio-content", 
            partial: "summaries/show/audio_generating_state",
            locals: { video_id: video_id, message: message }),
          turbo_stream.prepend("flash-messages", 
            partial: "shared/flash_message", 
            locals: { type: flash_type, message: message })
        ]
      end
      format.html { redirect_to summary_path(video_id), notice: message }
    end
  end

  # Serves audio content with proper headers for streaming
  # @param audio_content [String] Binary audio content
  # @param audio_id [String] Audio ID for filename
  # @param mime_type [String] MIME type of the audio (default: "audio/wav")
  def serve_audio_content(audio_content, audio_id, mime_type: "audio/wav")
    # Set appropriate headers for audio streaming
    response.headers['Content-Type'] = mime_type
    response.headers['Content-Length'] = audio_content.length.to_s
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Cache-Control'] = 'public, max-age=3600' # Cache for 1 hour
    response.headers['X-Content-Type-Options'] = 'nosniff' # Security header
    
    # Send the audio content with proper filename
    file_extension = mime_type.include?('wav') ? 'wav' : 'mp3'
    filename = "#{audio_id}.#{file_extension}"
    
    log_info "Successfully serving audio file", context: { 
      audio_id: audio_id,
      mime_type: mime_type,
      content_length: audio_content.length,
      filename: filename
    }
    
    send_data audio_content, 
              type: mime_type, 
              disposition: 'inline',
              filename: filename
  end

  # Decodes base64 audio content with error handling
  # @param base64_content [String] Base64 encoded audio content
  # @param audio_id [String] Audio ID for logging
  # @return [String, nil] Decoded binary content or nil if failed
  def decode_audio_content(base64_content, audio_id)
    return nil if base64_content.blank?

    begin
      decode_start = Time.current
      audio_content = Base64.strict_decode64(base64_content)  # Use strict_decode64 for better performance
      decode_duration = (Time.current - decode_start).round(3)
      
      log_info "Audio content decoded", context: {
        audio_id: audio_id,
        decode_duration_ms: (decode_duration * 1000).round(1),
        content_size: audio_content.length,
        content_size_mb: (audio_content.length / 1024.0 / 1024.0).round(2)
      }
      
      # Validate decoded content
      if audio_content.blank? || audio_content.length < 100
        log_error "Decoded audio content is invalid", context: { 
          audio_id: audio_id,
          content_length: audio_content&.length 
        }
        return nil
      end
      
      audio_content
    rescue ArgumentError => e
      log_error "Failed to decode base64 audio content", context: { 
        audio_id: audio_id, 
        error: e.message,
        content_length: base64_content&.length
      }
      nil
    end
  end

  # Simple rate limiting using Rails cache
  # @param key [String] Rate limit key (usually user/IP based)
  # @param limit [Integer] Maximum requests allowed
  # @param window [Integer] Time window in seconds
  # @return [Boolean] True if rate limited
  def rate_limited?(key, limit:, window:)
    current_count = Rails.cache.read(key) || 0
    
    if current_count >= limit
      true
    else
      # Increment counter with expiration
      Rails.cache.write(key, current_count + 1, expires_in: window.seconds)
      false
    end
  end
end
