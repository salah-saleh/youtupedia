import sys
import json
from google.ai.generativelanguage_v1beta.types import content
from gemini_base_client import GeminiBaseClient

class GeminiExpandedTakeawayClient(GeminiBaseClient):
    """
    Gemini client specifically for expanding takeaway points.
    Inherits common functionality from GeminiBaseClient.
    """
    
    def get_response_schema(self):
        """Define the response schema for takeaway expansion."""
        return content.Schema(
            type=content.Type.OBJECT,
            enum=[],
            required=["expanded_takeaway"],
            properties={
                "expanded_takeaway": content.Schema(
                    type=content.Type.STRING,
                ),
            },
        )
    
    def validate_response(self, json_response):
        """Validate the expanded takeaway response structure."""
        assert "expanded_takeaway" in json_response, "Missing expanded_takeaway field"
        return True
    
    def get_operation_type(self):
        """
        Get the operation type for this client.
        
        Returns:
            str: Operation type for takeaway expansion
        """
        return "takeaway_expansion"

if __name__ == "__main__":
    # Read input from stdin
    input_data = json.loads(sys.stdin.read())
    
    # Create client instance and run
    client = GeminiExpandedTakeawayClient()
    result = client.run(input_data)
    print(result) 