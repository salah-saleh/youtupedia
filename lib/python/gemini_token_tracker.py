import sys
import json
import os
from abc import ABC, abstractmethod

class GeminiTokenTracker(ABC):
    """
    Base class for token tracking functionality across different Gemini API clients.
    Provides common token estimation and logging methods for cost tracking.
    """
    
    def __init__(self):
        """Initialize the token tracker."""
        pass
    
    def estimate_tokens_from_text(self, text):
        """
        Estimate token count from text using character-based approximation.
        This is consistent with the approach used in gemini_base_client.py.
        
        Args:
            text (str): Text to estimate tokens for
            
        Returns:
            int: Estimated token count
        """
        if not text:
            return 0
        
        # Rough approximation: 1 token ≈ 4 characters
        # This matches the estimation method used in gemini_base_client.py
        return max(1, int(len(text) / 4.0))
    
    def estimate_tts_tokens(self, input_text, voice_name, audio_duration=None):
        """
        Estimate token usage for TTS operations.
        
        For TTS, we consider:
        - Input tokens: Based on text length (similar to text generation)
        - Processing tokens: Additional tokens for voice synthesis processing
        - Voice complexity: Different voices may have different token costs
        
        Args:
            input_text (str): Input text for TTS
            voice_name (str): Voice used for synthesis
            audio_duration (float, optional): Duration of generated audio in seconds
            
        Returns:
            dict: Token usage estimation
        """
        try:
            # Base input tokens from text
            input_tokens = self.estimate_tokens_from_text(input_text)
            
            # Estimate processing tokens for TTS synthesis
            # This is a rough approximation - actual TTS processing may vary
            base_processing_tokens = max(50, int(input_tokens * 0.5))  # Minimum 50, or 50% of input
            
            # Voice complexity multiplier (some voices may be more complex)
            voice_multipliers = {
                "Algenib": 1.0,    # Standard voice
                "Algieba": 1.1,    # Slightly more complex
                "Aoede": 1.2,      # More expressive
                "Charon": 1.0      # Standard voice
            }
            voice_multiplier = voice_multipliers.get(voice_name, 1.0)
            
            # Apply voice complexity
            processing_tokens = int(base_processing_tokens * voice_multiplier)
            
            # Duration-based adjustment (longer audio may require more processing)
            if audio_duration and audio_duration > 0:
                duration_factor = max(1.0, audio_duration / 60.0)  # Scale based on minutes
                processing_tokens = int(processing_tokens * min(duration_factor, 2.0))  # Cap at 2x
            
            total_tokens = input_tokens + processing_tokens
            
            return {
                "input_tokens": input_tokens,
                "processing_tokens": processing_tokens,
                "total_tokens": total_tokens,
                "voice_name": voice_name,
                "voice_multiplier": voice_multiplier,
                "audio_duration": audio_duration,
                "estimation_method": "tts_character_based_approximation",
                "note": "TTS token counts are estimates based on text length + processing overhead"
            }
            
        except Exception as e:
            return {
                "input_tokens": None,
                "processing_tokens": None,
                "total_tokens": None,
                "voice_name": voice_name,
                "estimation_method": "failed",
                "error": str(e)
            }
    
    def create_safe_config_for_logging(self, config):
        """
        Create a JSON-serializable version of configuration for logging.
        Removes any non-serializable objects.
        
        Args:
            config (dict): Original configuration
            
        Returns:
            dict: Safe, serializable configuration
        """
        if not config:
            return {}
            
        safe_config = {}
        for key, value in config.items():
            try:
                # Test if the value is JSON serializable
                json.dumps(value)
                safe_config[key] = value
            except (TypeError, ValueError):
                # If not serializable, convert to string representation
                safe_config[key] = str(value)
                
        return safe_config
    
    def log_api_call_start(self, operation_type, video_id, model_name, input_text, voice_name=None, config=None):
        """
        Log the start of an API call with estimated token usage.
        
        Args:
            operation_type (str): Type of operation (e.g., "tts_generation", "summary_generation")
            video_id (str): Video ID for tracking
            model_name (str): Model being used
            input_text (str): Input text
            voice_name (str, optional): Voice name for TTS operations
            config (dict, optional): Configuration used
        """
        try:
            # Estimate tokens based on operation type
            if operation_type == "tts_generation" and voice_name:
                token_usage = self.estimate_tts_tokens(input_text, voice_name)
            else:
                # For non-TTS operations, use basic text estimation
                estimated_tokens = self.estimate_tokens_from_text(input_text)
                token_usage = {
                    "input_tokens": estimated_tokens,
                    "total_tokens": estimated_tokens,
                    "estimation_method": "character_based_approximation"
                }
            
            safe_config = self.create_safe_config_for_logging(config)
            
            log_data = {
                "message": "Gemini API call starting",
                "operation_type": operation_type,
                "video_id": video_id,
                "model": model_name,
                "estimated_input_tokens": token_usage.get("input_tokens"),
                "estimated_total_tokens": token_usage.get("total_tokens"),
                "text_length": len(input_text) if input_text else 0,
                "generation_config": safe_config
            }
            
            if voice_name:
                log_data["voice_name"] = voice_name
                log_data["processing_tokens"] = token_usage.get("processing_tokens")
            
            print(f"DEBUG: {json.dumps(log_data)}", file=sys.stderr)
            
        except Exception as e:
            print(f"DEBUG: Failed to log API call start: {str(e)}", file=sys.stderr)
    
    def log_api_call_completion(self, operation_type, video_id, model_name, success, elapsed_seconds, token_usage=None, error=None):
        """
        Log the completion of an API call with actual token usage.
        
        Args:
            operation_type (str): Type of operation
            video_id (str): Video ID for tracking
            model_name (str): Model used
            success (bool): Whether the call was successful
            elapsed_seconds (float): Time taken for the call
            token_usage (dict, optional): Actual or estimated token usage
            error (str, optional): Error message if failed
        """
        try:
            log_data = {
                "message": "Gemini API call completed",
                "operation_type": operation_type,
                "video_id": video_id,
                "model": model_name,
                "elapsed_seconds": round(elapsed_seconds, 3),
                "success": success
            }
            
            if token_usage:
                log_data.update({
                    "input_tokens": token_usage.get("input_tokens"),
                    "output_tokens": token_usage.get("output_tokens"),
                    "processing_tokens": token_usage.get("processing_tokens"),
                    "total_tokens": token_usage.get("total_tokens"),
                    "estimation_method": token_usage.get("estimation_method"),
                    "character_count": token_usage.get("character_count"),  # For TTS APIs
                    "data_source": "api_actual" if token_usage.get("estimation_method", "").startswith("api_provided") else "estimated"
                })
            
            if error:
                log_data["error"] = error
            
            print(f"DEBUG: {json.dumps(log_data)}", file=sys.stderr)
            
        except Exception as e:
            print(f"DEBUG: Failed to log API call completion: {str(e)}", file=sys.stderr)
    
    @abstractmethod
    def get_operation_type(self):
        """
        Abstract method to get the operation type for this client.
        
        Returns:
            str: Operation type (e.g., "tts_generation", "summary_generation")
        """
        pass
