import os
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled
from youtube_transcript_api.proxies import GenericProxyConfig
import sys
import json
import time
from random import uniform

# https://github.com/jdepoix/youtube-transcript-api/issues/303
# https://dashboard.nodemaven.com/

def get_transcript_with_retry(video_id, languages=None, max_retries=2, initial_delay=1):
    """
    Fetch YouTube transcript with retry logic and multi-language support.
    
    Args:
        video_id (str): YouTube video ID
        languages (list): List of language codes in priority order (e.g., ['es', 'en', 'auto'])
                         If None, defaults to ['en', 'auto'] for backward compatibility
        max_retries (int): Maximum number of retry attempts
        initial_delay (int): Initial delay between retries in seconds
    
    Returns:
        dict: Result dictionary with success status and transcript/error data
    """
    last_error = None
    
    # Default to all languages popular languages
    if languages is None:
        languages = ['en', 'ar', 'de', 'es', 'fr', 'it', 'ja', 'ko', 'pt', 'ru', 'zh']

    for attempt in range(max_retries):
        try:
            # Get proxy from environment variable
            proxy_url = os.environ.get('YOUTUBE_TRANSCRIPT_API_PROXY')
            if not proxy_url:
                print(json.dumps({
                    'success': False,
                    'error': 'YOUTUBE_TRANSCRIPT_API_PROXY environment variable is not set'
                }), file=sys.stderr)
                return {
                    'success': False,
                    'error': 'YOUTUBE_TRANSCRIPT_API_PROXY environment variable is not set'
                }

            # Create a proxy config object
            proxy_config = GenericProxyConfig(
                http_url=proxy_url,
                https_url=proxy_url
            )

            # Instantiate the API with the proxy config
            ytt_api = YouTubeTranscriptApi(proxy_config=proxy_config)

            # Fetch the transcript data and convert to raw format
            fetched_transcript = ytt_api.fetch(video_id, languages=languages)

            # Format the transcript
            formatted_transcript = []
            for entry in fetched_transcript:
                formatted_transcript.append({
                    'text': entry.text,
                    'start': entry.start,
                    'duration': entry.duration
                })

            return {
                'success': True,
                'transcript': formatted_transcript
            }

        except TranscriptsDisabled:
            return {
                'success': False,
                'error': 'Could not retrieve a transcript for the video (TranscriptsDisabled). '
            }
        except Exception as e:
            last_error = str(e)              
            if "Could not retrieve a transcript for the video" in str(e):
                return {
                    'success': False,
                    'error': str(e)
                }
            if attempt < max_retries - 1:
                # Calculate delay with exponential backoff and jitter
                delay = initial_delay * (2 ** attempt) + uniform(0, 0.1)
                time.sleep(delay)

    return {
        'success': False,
        'error': f"Failed after {max_retries} attempts. Last error: {last_error}"
    }

if __name__ == "__main__":
    try:
        # Read input from stdin
        input_data = json.loads(sys.stdin.read())
        video_id = input_data.get('video_id')
        languages = input_data.get('languages')  # Optional languages parameter
        
        if not video_id:
            print(json.dumps({
                'success': False,
                'error': 'Please provide a video_id'
            }))
            sys.exit(1)

        # Get and print transcript with retries and language support
        # If languages is None, function will use default to all popular languages
        result = get_transcript_with_retry(video_id, languages=languages)
        print(json.dumps(result))
    except json.JSONDecodeError as e:
        print(json.dumps({
            'success': False,
            'error': f'Invalid JSON input: {str(e)}'
        }))
    except Exception as e:
        print(json.dumps({
            'success': False,
            'error': f'Unexpected error: {str(e)}'
        }))