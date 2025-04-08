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

        # Process each message
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
            
            return {
                "success": True,
                "content": clean_text
            }
        except Exception as e:
            return {
                "success": False,
                "error": f"Failed to parse response: {str(e)}\nResponse was: {response.text}"
            }

    except Exception as e:
        return {
            "success": False,
            "error": str(e) + "\n" + str(response)
        }

if __name__ == "__main__":
    # Read input from stdin
    input_data = json.loads(sys.stdin.read())
    result = chat_completion(
        messages=input_data.get("messages", [])
    )
    print(json.dumps(result)) 