import sys
import json
from google.ai.generativelanguage_v1beta.types import content
from gemini_base_client import GeminiBaseClient

class GeminiSummaryClient(GeminiBaseClient):
    """
    Gemini client specifically for generating video summaries.
    Inherits common functionality from GeminiBaseClient.
    """
    
    def get_response_schema(self):
        """Define the response schema for summary generation."""
        return content.Schema(
            type=content.Type.OBJECT,
            enum=[],
            required=["tldr", "summary", "contents"],
            properties={
                "tldr": content.Schema(
                    type=content.Type.STRING,
                ),
                "summary": content.Schema(
                    type=content.Type.STRING,
                ),
                "contents": content.Schema(
                    type=content.Type.ARRAY,
                    items=content.Schema(
                        type=content.Type.OBJECT,
                        enum=[],
                        required=["topic", "takeaway"],
                        properties={
                            "topic": content.Schema(
                                type=content.Type.STRING,
                            ),
                            "takeaway": content.Schema(
                                type=content.Type.STRING,
                            ),
                        },
                    ),
                ),
            },
        )
    
    def validate_response(self, json_response):
        """Validate the summary response structure."""
        assert "tldr" in json_response, "Missing tldr field"
        assert "contents" in json_response, "Missing contents field"
        assert isinstance(json_response["contents"], list), "Contents must be an array"
        assert "summary" in json_response, "Missing summary field"
        
        for item in json_response["contents"]:
            assert "topic" in item, "Missing topic in content item"
            assert "takeaway" in item, "Missing takeaway in content item"
        
        return True

if __name__ == "__main__":
    # Read input from stdin
    input_data = json.loads(sys.stdin.read())
    
    # Create client instance and run
    client = GeminiSummaryClient()
    result = client.run(input_data)
    print(result) 