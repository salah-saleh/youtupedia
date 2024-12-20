import os
from youtube_transcript_api import YouTubeTranscriptApi
import sys
import json
import time
from random import uniform

# https://github.com/jdepoix/youtube-transcript-api/issues/303
# https://dashboard.nodemaven.com/

def get_transcript_with_retry(video_id, max_retries=3, initial_delay=1):
    last_error = None

    for attempt in range(max_retries):
        try:
            # Get proxy from environment variable
            proxy = os.environ.get('YOUTUBE_TRANSCRIPT_API_PROXY')
            if not proxy:
                print(json.dumps({
                    'success': False,
                    'error': 'YOUTUBE_TRANSCRIPT_API_PROXY environment variable is not set'
                }), file=sys.stderr)
                return {
                    'success': False,
                    'error': 'YOUTUBE_TRANSCRIPT_API_PROXY environment variable is not set'
                }

            # Get transcript list with proxy
            transcript_list = YouTubeTranscriptApi.get_transcript(
                video_id,
                proxies={
                    "http": proxy,
                    "https": proxy
                }
            )

            # Format the transcript
            formatted_transcript = []
            for entry in transcript_list:
                formatted_transcript.append({
                    'text': entry['text'],
                    'start': entry['start'],
                    'duration': entry['duration']
                })

            return {
                'success': True,
                'transcript': formatted_transcript
            }

        except Exception as e:
            last_error = str(e)
            if attempt < max_retries - 1:
                # Calculate delay with exponential backoff and jitter
                delay = initial_delay * (2 ** attempt) + uniform(0, 0.1)
                print(json.dumps({
                    'success': False,
                    'error': f"Attempt {attempt + 1} failed: {str(e)}. Retrying in {delay:.1f} seconds..."
                }), file=sys.stderr)
                time.sleep(delay)
            else:
                print(json.dumps({
                    'success': False,
                    'error': f"All {max_retries} attempts failed. Last error: {str(e)}"
                }), file=sys.stderr)

    return {
        'success': False,
        'error': f"Failed after {max_retries} attempts. Last error: {last_error}"
    }

if __name__ == "__main__":
    # Check if video ID is provided
    if len(sys.argv) != 2:
        print(json.dumps({
            'success': False,
            'error': 'Please provide a YouTube video ID'
        }))
        sys.exit(1)

    # Get video ID from command line argument
    video_id = sys.argv[1]

    # Get and print transcript with retries
    result = get_transcript_with_retry(video_id)
    print(json.dumps(result))