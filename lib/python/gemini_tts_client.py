import sys
import json
import base64
import struct
import mimetypes
import os
import time
from google import genai
from google.genai import types
from gemini_token_tracker import GeminiTokenTracker

class GeminiTtsClient(GeminiTokenTracker):
    """
    Gemini Text-to-Speech client using the Gemini 2.5 Pro Preview TTS API.
    Handles text-to-speech conversion with proper audio format handling.
    """
    
    def __init__(self, config=None):
        """
        Initialize the TTS client with configuration.
        
        Args:
            config (dict): Configuration dictionary with TTS parameters
        """
        super().__init__()  # Initialize the token tracker
        self.config = config or self.get_default_config()
        self.model = "gemini-2.5-flash-preview-tts"
        
    def get_default_config(self):
        """Get default configuration for TTS API calls."""
        return {
            # Voice configuration
            "voice_name": "Algenib",  # Default voice
            
            # Generation parameters
            "temperature": 1.0,
            
            # Audio output settings
            "output_format": "wav",  # Always output as WAV for browser compatibility
        }
    
    def init_gemini(self):
        """Initialize Gemini with API key."""
        api_key = os.environ.get('GEMINI_API_KEY')
        if not api_key:
            return {"success": False, "error": "GEMINI_API_KEY not set"}
        
        self.api_key = api_key
        return {"success": True}
    
    def validate_inputs(self, text, voice_name):
        """
        Validate input parameters for TTS generation.
        
        Args:
            text (str): Text to convert to speech
            voice_name (str): Voice name to use
            
        Returns:
            dict: Validation result
        """
        if not text or len(text.strip()) == 0:
            return {"success": False, "error": "Text content is required"}
        
        # Basic text length validation
        text = text.strip()
        if len(text) < 10:
            return {"success": False, "error": "Text is too short for TTS generation (minimum 10 characters)"}
        
        if len(text) > 5000:
            return {"success": False, "error": "Text is too long for TTS generation (maximum 5000 characters)"}
        
        # Voice validation
        allowed_voices = ['Algenib', 'Algieba', 'Aoede', 'Charon']
        if voice_name and voice_name not in allowed_voices:
            return {"success": False, "error": f"Invalid voice selection. Allowed voices: {', '.join(allowed_voices)}"}
        
        return {"success": True, "sanitized_text": text}
    
    def get_operation_type(self):
        """
        Get the operation type for this TTS client.
        
        Returns:
            str: Operation type for TTS generation
        """
        return "tts_generation"
    
    def generate_audio(self, text, voice_name=None, video_id=None):
        """
        Generate audio from text using Gemini TTS API.
        
        Args:
            text (str): Text to convert to speech
            voice_name (str): Voice name to use (optional)
            video_id (str): Video ID for tracking (optional)
            
        Returns:
            dict: Result with success status and audio data or error
        """
        start_time = time.time()
        voice_name = voice_name or self.config["voice_name"]
        
        try:
            # Log API call start with token estimation
            self.log_api_call_start(
                operation_type=self.get_operation_type(),
                video_id=video_id,
                model_name=self.model,
                input_text=text,
                voice_name=voice_name,
                config=self.config
            )
            
            # Initialize Gemini
            init_result = self.init_gemini()
            if not init_result["success"]:
                elapsed = time.time() - start_time
                self.log_api_call_completion(
                    self.get_operation_type(), video_id, self.model, 
                    False, elapsed, error=init_result["error"]
                )
                return init_result
            
            # Validate inputs
            validation = self.validate_inputs(text, voice_name)
            if not validation["success"]:
                elapsed = time.time() - start_time
                self.log_api_call_completion(
                    self.get_operation_type(), video_id, self.model, 
                    False, elapsed, error=validation["error"]
                )
                return validation
            
            sanitized_text = validation["sanitized_text"]
            
            # Create Gemini client
            client = genai.Client(api_key=self.api_key)
            
            # Prepare the request
            contents = [
                types.Content(
                    role="user",
                    parts=[
                        types.Part.from_text(text=sanitized_text),
                    ],
                ),
            ]
            
            generate_content_config = types.GenerateContentConfig(
                temperature=self.config["temperature"],
                response_modalities=["audio"],
                speech_config=types.SpeechConfig(
                    voice_config=types.VoiceConfig(
                        prebuilt_voice_config=types.PrebuiltVoiceConfig(
                            voice_name=voice_name
                        )
                    )
                ),
            )
            
            # Make the streaming API call
            audio_data = b""
            mime_type = None
            chunk_count = 0
            actual_usage_metadata = None
            
            for chunk in client.models.generate_content_stream(
                model=self.model,
                contents=contents,
                config=generate_content_config,
            ):
                chunk_count += 1
                print(f"DEBUG: Processing chunk {chunk_count}", file=sys.stderr)
                
                # Check for usage metadata in the chunk
                if hasattr(chunk, 'usage_metadata') and chunk.usage_metadata:
                    actual_usage_metadata = chunk.usage_metadata
                    print(f"DEBUG: Found usage_metadata in chunk {chunk_count}: {actual_usage_metadata}", file=sys.stderr)
                
                if (
                    chunk.candidates is None
                    or chunk.candidates[0].content is None
                    or chunk.candidates[0].content.parts is None
                ):
                    print(f"DEBUG: Chunk {chunk_count} - no candidates/content/parts", file=sys.stderr)
                    continue
                    
                if (chunk.candidates[0].content.parts[0].inline_data and 
                    chunk.candidates[0].content.parts[0].inline_data.data):
                    
                    inline_data = chunk.candidates[0].content.parts[0].inline_data
                    chunk_audio_data = inline_data.data
                    mime_type = inline_data.mime_type
                    
                    print(f"DEBUG: Chunk {chunk_count} - audio data size: {len(chunk_audio_data)}", file=sys.stderr)
                    
                    # Accumulate audio data from all chunks
                    audio_data += chunk_audio_data
                else:
                    print(f"DEBUG: Chunk {chunk_count} - no inline_data", file=sys.stderr)
            
            print(f"DEBUG: Total audio data size: {len(audio_data)}", file=sys.stderr)
            if actual_usage_metadata:
                print(f"DEBUG: Final usage_metadata: {actual_usage_metadata}", file=sys.stderr)
            
            if audio_data and mime_type:
                # Convert the audio data
                result = self.process_audio_data(
                    audio_data, 
                    mime_type,
                    voice_name,
                    len(sanitized_text)
                )
                
                # Log successful completion with token usage
                elapsed = time.time() - start_time
                if result.get("success"):
                    # Use actual token usage from API if available, otherwise estimate
                    if actual_usage_metadata:
                        token_usage = self.extract_actual_token_usage(
                            actual_usage_metadata, 
                            sanitized_text, 
                            voice_name, 
                            result.get("duration_seconds")
                        )
                    else:
                        # Fall back to estimation if API doesn't provide actual usage
                        token_usage = self.estimate_tts_tokens(
                            sanitized_text, 
                            voice_name, 
                            result.get("duration_seconds")
                        )
                        # Mark as estimated since we didn't get actual data
                        token_usage["estimation_method"] = "tts_character_based_approximation_fallback"
                        token_usage["note"] = "API did not provide usage metadata, using estimation"
                    
                    self.log_api_call_completion(
                        self.get_operation_type(), video_id, self.model, 
                        True, elapsed, token_usage=token_usage
                    )
                    
                    # Add token usage to the result for Rails
                    result["token_usage"] = token_usage
                else:
                    self.log_api_call_completion(
                        self.get_operation_type(), video_id, self.model, 
                        False, elapsed, error=result.get("error")
                    )
                
                return result
            else:
                elapsed = time.time() - start_time
                error_msg = "No audio data in response"
                self.log_api_call_completion(
                    self.get_operation_type(), video_id, self.model, 
                    False, elapsed, error=error_msg
                )
                return {"success": False, "error": error_msg}
                
        except Exception as e:
            elapsed = time.time() - start_time
            error_msg = f"TTS generation failed: {str(e)}"
            self.log_api_call_completion(
                self.get_operation_type(), video_id, self.model, 
                False, elapsed, error=error_msg
            )
            return {"success": False, "error": error_msg}
    
    def process_audio_data(self, audio_data, mime_type, voice_name, text_length):
        """
        Process the raw audio data from Gemini API.
        
        Args:
            audio_data (bytes): Raw audio data (not base64 encoded)
            mime_type (str): MIME type of the audio data
            voice_name (str): Voice used for generation
            text_length (int): Length of input text
            
        Returns:
            dict: Processed audio data
        """
        try:
            # audio_data is already raw bytes, no need to decode
            raw_audio = audio_data
            
            # Convert PCM to WAV format
            wav_audio = self.convert_pcm_to_wav(raw_audio, mime_type)
            
            # Re-encode as base64 for storage
            wav_base64 = base64.b64encode(wav_audio).decode('utf-8')
            
            # Estimate duration
            duration_seconds = self.estimate_duration(len(raw_audio))
            
            return {
                "success": True,
                "audio_content": wav_base64,
                "mime_type": "audio/wav",
                "voice": voice_name,
                "text_length": text_length,
                "duration_seconds": duration_seconds,
                "data_size": len(wav_audio),
                "original_mime_type": mime_type,
                "original_size": len(raw_audio)
            }
            
        except Exception as e:
            return {"success": False, "error": f"Failed to process audio data: {str(e)}"}
    
    def convert_pcm_to_wav(self, audio_data, mime_type):
        """
        Convert raw PCM audio data to WAV format.
        Based on the user-provided Python conversion code.
        
        Args:
            audio_data (bytes): Raw PCM audio data
            mime_type (str): MIME type of the audio data
            
        Returns:
            bytes: WAV formatted audio data
        """
        parameters = self.parse_audio_mime_type(mime_type)
        bits_per_sample = parameters["bits_per_sample"]
        sample_rate = parameters["rate"]
        num_channels = 1  # Mono audio
        
        data_size = len(audio_data)
        bytes_per_sample = bits_per_sample // 8
        block_align = num_channels * bytes_per_sample
        byte_rate = sample_rate * block_align
        chunk_size = 36 + data_size  # 36 bytes for header fields before data chunk size
        
        # Create WAV header using struct.pack
        header = struct.pack(
            "<4sI4s4sIHHIIHH4sI",
            b"RIFF",          # ChunkID
            chunk_size,       # ChunkSize (total file size - 8 bytes)
            b"WAVE",          # Format
            b"fmt ",          # Subchunk1ID
            16,               # Subchunk1Size (16 for PCM)
            1,                # AudioFormat (1 for PCM)
            num_channels,     # NumChannels
            sample_rate,      # SampleRate
            byte_rate,        # ByteRate
            block_align,      # BlockAlign
            bits_per_sample,  # BitsPerSample
            b"data",          # Subchunk2ID
            data_size         # Subchunk2Size (size of audio data)
        )
        
        return header + audio_data
    
    def parse_audio_mime_type(self, mime_type):
        """
        Parse audio parameters from MIME type string.
        
        Args:
            mime_type (str): The audio MIME type string (e.g., "audio/L16;rate=24000")
            
        Returns:
            dict: Dictionary with "bits_per_sample" and "rate" keys
        """
        bits_per_sample = 16  # Default
        rate = 24000          # Default
        
        # Extract rate from parameters
        parts = mime_type.split(";")
        for param in parts:
            param = param.strip()
            if param.lower().startswith("rate="):
                try:
                    rate_str = param.split("=", 1)[1]
                    rate = int(rate_str)
                except (ValueError, IndexError):
                    pass  # Keep default rate
            elif param.startswith("audio/L"):
                try:
                    bits_per_sample = int(param.split("L", 1)[1])
                except (ValueError, IndexError):
                    pass  # Keep default bits_per_sample
        
        return {"bits_per_sample": bits_per_sample, "rate": rate}
    
    def estimate_duration(self, data_size):
        """
        Estimate audio duration based on audio data size and format.
        
        Args:
            data_size (int): Size of audio data in bytes
            
        Returns:
            float: Estimated duration in seconds
        """
        # For PCM audio: duration = data_size / (sample_rate * channels * bytes_per_sample)
        # Assuming 16-bit mono at 24kHz
        sample_rate = 24000
        channels = 1
        bytes_per_sample = 2  # 16-bit = 2 bytes
        
        duration = data_size / (sample_rate * channels * bytes_per_sample)
        print(f"DEBUG: Duration calculation - data_size: {data_size}, sample_rate: {sample_rate}, channels: {channels}, bytes_per_sample: {bytes_per_sample}, duration: {duration}", file=sys.stderr)
        return round(duration, 1)
    
    def extract_actual_token_usage(self, usage_metadata, input_text, voice_name, audio_duration=None):
        """
        Extract actual token usage from the Gemini API response metadata.
        
        Args:
            usage_metadata: The usage_metadata object from the API response
            input_text (str): Input text for context
            voice_name (str): Voice used for synthesis
            audio_duration (float, optional): Duration of generated audio in seconds
            
        Returns:
            dict: Actual token usage information
        """
        try:
            # Extract actual token counts from the API response
            prompt_tokens = getattr(usage_metadata, 'prompt_token_count', None)
            candidates_tokens = getattr(usage_metadata, 'candidates_token_count', None)
            total_tokens = getattr(usage_metadata, 'total_token_count', None)
            
            # For TTS, there might be different fields or calculation methods
            # The API might report character count instead of tokens for TTS
            character_count = getattr(usage_metadata, 'character_count', None)
            
            if prompt_tokens is not None and candidates_tokens is not None:
                # Standard token-based response
                actual_total = prompt_tokens + candidates_tokens
                
                return {
                    "input_tokens": prompt_tokens,
                    "output_tokens": candidates_tokens,  # For TTS, this might be processing tokens
                    "processing_tokens": candidates_tokens,  # TTS-specific alias
                    "total_tokens": total_tokens or actual_total,
                    "voice_name": voice_name,
                    "audio_duration": audio_duration,
                    "estimation_method": "api_provided_actual",
                    "note": "Actual token usage from Gemini API response"
                }
            elif character_count is not None:
                # Character-based response (more likely for TTS)
                # Convert characters to estimated tokens for consistency
                estimated_input_tokens = self.estimate_tokens_from_text(input_text)
                
                return {
                    "input_tokens": estimated_input_tokens,
                    "character_count": character_count,
                    "processing_tokens": max(50, int(character_count * 0.25)),  # Rough processing estimate
                    "total_tokens": estimated_input_tokens + max(50, int(character_count * 0.25)),
                    "voice_name": voice_name,
                    "audio_duration": audio_duration,
                    "estimation_method": "api_provided_character_count",
                    "note": f"API provided character count ({character_count}), estimated processing tokens"
                }
            else:
                # Fallback: use the estimation method but mark as API-attempted
                estimated = self.estimate_tts_tokens(input_text, voice_name, audio_duration)
                estimated["estimation_method"] = "api_metadata_incomplete_fallback_to_estimation"
                estimated["note"] = f"API provided usage_metadata but missing expected fields: {dir(usage_metadata)}"
                return estimated
                
        except Exception as e:
            # If extraction fails, fall back to estimation
            estimated = self.estimate_tts_tokens(input_text, voice_name, audio_duration)
            estimated["estimation_method"] = "api_extraction_failed_fallback_to_estimation"
            estimated["note"] = f"Failed to extract API usage data: {str(e)}"
            return estimated
    
    def run(self, input_data):
        """
        Main entry point for running the TTS client.
        
        Args:
            input_data (dict): Input data with text and voice parameters
            
        Returns:
            str: JSON result of TTS generation
        """
        try:
            text = input_data.get("text", "")
            voice_name = input_data.get("voice_name")
            video_id = input_data.get("video_id")
            
            result = self.generate_audio(text, voice_name, video_id)
            
            # Add metadata for tracking
            if result["success"]:
                result["video_id"] = video_id
                result["model"] = self.model
                result["config"] = self.config
            
            return json.dumps(result)
            
        except Exception as e:
            error_result = {
                "success": False,
                "error": f"TTS client error: {str(e)}"
            }
            return json.dumps(error_result)

if __name__ == "__main__":
    # Read input from stdin
    input_data = json.loads(sys.stdin.read())
    
    # Create client instance and run
    client = GeminiTtsClient()
    result = client.run(input_data)
    print(result)
