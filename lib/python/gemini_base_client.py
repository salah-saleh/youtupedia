import sys
import json
import os
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content
from abc import ABC, abstractmethod
from gemini_token_tracker import GeminiTokenTracker

class GeminiBaseClient(GeminiTokenTracker, ABC):
    """
    Base class for Gemini API interactions with common functionality.
    Handles initialization, configuration, and basic API calls.
    """
    
    def __init__(self, config=None):
        """
        Initialize the Gemini client with configuration.
        
        Args:
            config (dict): Configuration dictionary with Gemini parameters
        """
        super().__init__()  # Initialize the token tracker
        self.config = config or self.get_default_config()
        self.model_name = self.config.get("model_name", "gemini-2.0-flash")
        
    def get_default_config(self):
        """Get default configuration for Gemini API calls."""
        return {
            # Gemini model to use for API calls
            # - gemini-2.0-flash: Fast, efficient model (default)
            # - gemini-2.0-flash-exp: Experimental version with extended capabilities
            # - gemini-1.5-flash: Previous generation, still powerful
            "model_name": "gemini-2.0-flash",
            
            # Controls randomness and creativity in responses
            # - 0.0: Very predictable, consistent outputs (good for summaries)
            # - 1.0: Balanced creativity (default)
            # - 2.0: Maximum creativity, varied outputs (good for content generation)
            "temperature": 1.0,
            
            # Nucleus sampling - controls vocabulary diversity
            # - 0.1: Only considers top 10% of possible tokens (narrow vocabulary)
            # - 0.95: Considers top 95% of possible tokens (default, balanced)
            # - 1.0: Considers all possible tokens (maximum diversity)
            "top_p": 0.95,
            
            # Limits the number of possible next tokens to consider
            # - 10: Only considers top 10 possibilities (highly predictable)
            # - 40: Considers top 40 possibilities (default, balanced)
            # - 100: Considers top 100 possibilities (maximum variety)
            "top_k": 40,
            
            # Maximum number of tokens the AI can generate in response
            # - 5000: Short responses (good for quick answers)
            # - 20000: Medium responses (default, good for summaries)
            # - 50000: Long responses (good for detailed content)
            "max_output_tokens": 20000,
            # Response format - always JSON for structured output
            "response_mime_type": "application/json"
        }
    
    def init_gemini(self):
        """Initialize Gemini with API key."""
        api_key = os.environ.get('GEMINI_API_KEY')
        if not api_key:
            return {"success": False, "error": "GEMINI_API_KEY not set"}
        
        genai.configure(api_key=api_key)
        return {"success": True}
    
    def extract_context_from_input(self, messages):
        """
        Extract additional context (video_id, operation_type, config) from input.
        
        Args:
            messages: Input messages or dict with context
            
        Returns:
            tuple: (messages, video_id, operation_type, config)
        """
        video_id = None
        operation_type = None
        config = None
        
        # Check if messages is a dict with additional context
        if isinstance(messages, dict) and "messages" in messages:
            video_id = messages.get("video_id")
            operation_type = messages.get("operation_type")
            config = messages.get("config")
            messages = messages["messages"]
            
        return messages, video_id, operation_type, config
    
    def parse_messages(self, messages):
        """
        Parse messages to extract system and user content.
        
        Args:
            messages: List of message dictionaries
            
        Returns:
            tuple: (system_instruction, model_content)
        """
        system_instruction = None
        model_content = None
        
        for message in messages:
            role = message.get("role")
            msg_content = message.get("content")
            
            if role == "system":
                system_instruction = msg_content
            elif role == "user":
                model_content = msg_content
            elif role == "assistant":
                # For context only, no need to send
                continue
                
        return system_instruction, model_content
    
    def create_generation_config(self, response_schema):
        """
        Create generation configuration with response schema.
        
        Args:
            response_schema: The response schema for structured output
            
        Returns:
            dict: Generation configuration
        """
        config = {
            "temperature": self.config.get("temperature", 1.0),
            "top_p": self.config.get("top_p", 0.95),
            "top_k": self.config.get("top_k", 40),
            "max_output_tokens": self.config.get("max_output_tokens", 20000),
            "response_schema": response_schema,
            "response_mime_type": self.config.get("response_mime_type", "application/json")
        }
        return config
    
    def create_model(self, generation_config, system_instruction):
        """
        Create and configure the Gemini model.
        
        Args:
            generation_config: Generation configuration
            system_instruction: System instruction for the model
            
        Returns:
            GenerativeModel: Configured Gemini model
        """
        model = genai.GenerativeModel(
            model_name=self.model_name,
            generation_config=generation_config,
            system_instruction=system_instruction,
        )
        return model
    
    def call_gemini_api(self, model, model_content):
        """
        Make the actual API call to Gemini.
        
        Args:
            model: Configured Gemini model
            model_content: User content to send
            
        Returns:
            Response: Gemini API response
        """
        chat_session = model.start_chat(history=[])
        response = chat_session.send_message(model_content)
        return response
    
    def extract_token_usage(self, response, user_content, system_content):
        """
        Extract token usage information from the Gemini response.
        Uses the inherited token estimation methods from GeminiTokenTracker.
        
        Args:
            response: Gemini API response
            user_content: User message content
            system_content: System instruction content
            
        Returns:
            dict: Token usage information
        """
        try:
            # Combine input content for estimation
            combined_input = (system_content or "") + (user_content or "")
            estimated_input_tokens = self.estimate_tokens_from_text(combined_input)
            
            # Estimate output tokens from response
            estimated_output_tokens = self.estimate_tokens_from_text(response.text if response else "")
            
            total_tokens = estimated_input_tokens + estimated_output_tokens
            
            return {
                "input_tokens": estimated_input_tokens,
                "output_tokens": estimated_output_tokens,
                "total_tokens": total_tokens,
                "estimation_method": "character_based_approximation",
                "note": "Token counts are estimates based on character length (1 token ≈ 4 chars)"
            }
        except Exception as e:
            return {
                "input_tokens": None,
                "output_tokens": None,
                "total_tokens": None,
                "estimation_method": "failed",
                "error": str(e)
            }
    
    def create_safe_generation_config(self, generation_config):
        """
        Create a JSON-serializable version of generation config.
        Uses the inherited method from GeminiTokenTracker.
        
        Args:
            generation_config: Original generation config
            
        Returns:
            dict: Safe, serializable generation config
        """
        # Use the inherited method for consistency
        return self.create_safe_config_for_logging(generation_config)
    
    def create_success_response(self, clean_text, token_usage, video_id, operation_type, generation_config):
        """
        Create a standardized success response.
        
        Args:
            clean_text: Cleaned response text
            token_usage: Token usage information
            video_id: Video ID for tracking
            operation_type: Operation type for tracking
            generation_config: Generation configuration used
            
        Returns:
            dict: Standardized success response
        """
        safe_generation_config = self.create_safe_generation_config(generation_config)
        
        return {
            "success": True,
            "content": clean_text,
            "token_usage": token_usage,
            "video_id": video_id,
            "operation_type": operation_type,
            "model": self.model_name,
            "generation_config": safe_generation_config
        }
    
    def create_error_response(self, error_msg, response=None):
        """
        Create a standardized error response.
        
        Args:
            error_msg: Error message
            response: Optional response object for additional context
            
        Returns:
            dict: Standardized error response
        """
        if response:
            try:
                error_msg += f"\nResponse text: {response.text if hasattr(response, 'text') else 'No text attribute'}"
            except:
                error_msg += "\nResponse object exists but couldn't extract text"
        
        return {
            "success": False,
            "error": error_msg
        }
    
    @abstractmethod
    def get_response_schema(self):
        """
        Abstract method to define response schema for each client type.
        
        Returns:
            content.Schema: Response schema for the specific client
        """
        pass
    
    @abstractmethod
    def validate_response(self, json_response):
        """
        Abstract method to validate response structure for each client type.
        
        Args:
            json_response: Parsed JSON response
            
        Returns:
            bool: True if valid, raises AssertionError if not
        """
        pass
    
    def chat_completion(self, messages):
        """
        Main method to handle chat completion with Gemini.
        
        Args:
            messages: Input messages with optional context
            
        Returns:
            dict: Response with success status and content
        """
        try:
            # Initialize Gemini
            init_result = self.init_gemini()
            if not init_result["success"]:
                return init_result
            
            # Extract context and parse messages
            messages, video_id, operation_type, config = self.extract_context_from_input(messages)
            
            # Update config if provided
            if config:
                self.config.update(config)
                self.model_name = self.config.get("model_name", "gemini-2.0-flash")
            
            system_instruction, model_content = self.parse_messages(messages)
            
            if not system_instruction or not model_content:
                return {
                    "success": False,
                    "error": "Missing required messages"
                }
            
            # Create generation config and model
            response_schema = self.get_response_schema()
            generation_config = self.create_generation_config(response_schema)
            model = self.create_model(generation_config, system_instruction)
            
            # Make API call
            response = self.call_gemini_api(model, model_content)
            
            # Parse and validate response
            try:
                # Clean up response text
                clean_text = response.text.strip()
                if clean_text.startswith("```") and clean_text.endswith("```"):
                    clean_text = clean_text[clean_text.find("{"):clean_text.rfind("}")+1]
                
                json_response = json.loads(clean_text)
                
                # Validate response structure
                self.validate_response(json_response)
                
                # Extract token usage and create response
                token_usage = self.extract_token_usage(response, model_content, system_instruction)
                
                return self.create_success_response(
                    clean_text, token_usage, video_id, operation_type, generation_config
                )
                
            except Exception as e:
                return self.create_error_response(
                    f"Failed to parse response: {str(e)}\nResponse was: {response.text if response else 'No response'}"
                )
                
        except Exception as e:
            return self.create_error_response(str(e))
    
    def run(self, input_data):
        """
        Main entry point for running the client.
        
        Args:
            input_data: Input data from stdin
            
        Returns:
            dict: Result of chat completion
        """
        result = self.chat_completion(input_data)
        
        # Add safety check for JSON serialization
        try:
            json_result = json.dumps(result)
            return json_result
        except Exception as e:
            # If serialization fails, create a safe error response
            error_result = {
                "success": False,
                "error": f"Failed to serialize result: {str(e)}",
                "original_result_keys": list(result.keys()) if isinstance(result, dict) else "Not a dict"
            }
            return json.dumps(error_result)
