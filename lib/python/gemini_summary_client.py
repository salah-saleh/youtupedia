import sys
import json
import os
import google.generativeai as genai
from google.ai.generativelanguage_v1beta.types import content

def init_gemini():
    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        return {"success": False, "error": "GEMINI_API_KEY not set"}
    
    genai.configure(api_key=api_key)
    return {"success": True}

def chat_completion(messages):
    try:
        init_result = init_gemini()
        if not init_result["success"]:
            return init_result

        # Extract additional context from input
        video_id = None
        operation_type = None
        
        # Check if messages is a dict with additional context
        if isinstance(messages, dict) and "messages" in messages:
            video_id = messages.get("video_id")
            operation_type = messages.get("operation_type")
            messages = messages["messages"]

        # Process each message
        system_instruction = None
        model_content = None
        for message in messages:
            role = message["role"]
            msg_content = message["content"]
            
            if role == "system":
                system_instruction = msg_content
            elif role == "user":
                model_content = msg_content
            elif role == "assistant":
                # For context only, no need to send
                continue   

        generation_config = {
            "temperature": 1,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 20000,
            "response_schema": content.Schema(
                type = content.Type.OBJECT,
                enum = [],
                required = ["tldr", "summary", "contents"],
                properties = {
                    "tldr": content.Schema(
                        type = content.Type.STRING,
                    ),
                    "summary": content.Schema(
                        type = content.Type.STRING,
                    ),
                    "contents": content.Schema(
                        type = content.Type.ARRAY,
                        items = content.Schema(
                            type = content.Type.OBJECT,
                            enum = [],
                            required = ["topic", "takeaway"],
                            properties = {
                                "topic": content.Schema(
                                    type = content.Type.STRING,
                                ),
                                "takeaway": content.Schema(
                                    type = content.Type.STRING,
                                ),
                            },
                        ),
                    ),
                },
            ),
            "response_mime_type": "application/json",
        }                  

        model = genai.GenerativeModel(
            model_name="gemini-2.0-flash",
            generation_config=generation_config,
            system_instruction=system_instruction,
        )
        chat_session = model.start_chat(
            history=[
            ]
        )

        response = chat_session.send_message(model_content)

        # Parse and validate the response
        try:
            # Clean up the response text (remove any markdown formatting if present)
            clean_text = response.text.strip()
            if clean_text.startswith("```") and clean_text.endswith("```"):
                clean_text = clean_text[clean_text.find("{"):clean_text.rfind("}")+1]
            
            json_response = json.loads(clean_text)
            
            # Validate the structure
            assert "tldr" in json_response, "Missing tldr field"
            assert "contents" in json_response, "Missing contents field"
            assert isinstance(json_response["contents"], list), "Contents must be an array"
            assert "summary" in json_response, "Missing summary field"
            
            for item in json_response["contents"]:
                assert "topic" in item, "Missing topic in content item"
                assert "takeaway" in item, "Missing takeaway in content item"
            
            # Extract token usage information if available
            token_usage = extract_token_usage(response, model_content, system_instruction)
            
            # Ensure generation_config is JSON-serializable
            safe_generation_config = {
                "temperature": generation_config.get("temperature"),
                "top_p": generation_config.get("top_p"),
                "top_k": generation_config.get("top_k"),
                "max_output_tokens": generation_config.get("max_output_tokens"),
                "response_mime_type": generation_config.get("response_mime_type")
            }
            
            return {
                "success": True,
                "content": clean_text,
                "token_usage": token_usage,
                "video_id": video_id,
                "operation_type": operation_type,
                "model": "gemini-2.0-flash",
                "generation_config": safe_generation_config
            }
        except Exception as e:
            return {
                "success": False,
                "error": f"Failed to parse response: {str(e)}\nResponse was: {response.text if response else 'No response'}"
            }

    except Exception as e:
        # Ensure we don't try to serialize non-serializable objects
        error_msg = str(e)
        if 'response' in locals() and response:
            try:
                error_msg += f"\nResponse text: {response.text if hasattr(response, 'text') else 'No text attribute'}"
            except:
                error_msg += "\nResponse object exists but couldn't extract text"
        
        return {
            "success": False,
            "error": error_msg
        }

def extract_token_usage(response, user_content, system_content):
    """
    Extract token usage information from the Gemini response.
    Since Gemini doesn't provide direct token counts, we estimate them.
    """
    try:
        # Estimate input tokens (rough approximation: 1 token ≈ 4 characters)
        input_chars = len(system_content or "") + len(user_content or "")
        estimated_input_tokens = max(1, int(input_chars / 4.0))
        
        # Estimate output tokens from response
        output_chars = len(response.text or "")
        estimated_output_tokens = max(1, int(output_chars / 4.0))
        
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

if __name__ == "__main__":
    # Read input from stdin
    input_data = json.loads(sys.stdin.read())
    result = chat_completion(
        messages=input_data
    )
    
    # Add safety check for JSON serialization
    try:
        json_result = json.dumps(result)
        print(json_result)
    except Exception as e:
        # If serialization fails, create a safe error response
        error_result = {
            "success": False,
            "error": f"Failed to serialize result: {str(e)}",
            "original_result_keys": list(result.keys()) if isinstance(result, dict) else "Not a dict"
        }
        print(json.dumps(error_result)) 