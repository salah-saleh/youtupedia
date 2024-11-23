from youtube_transcript_api import YouTubeTranscriptApi
import sys
import json

def get_transcript(video_id):
    try:
        # Get transcript list
        transcript_list = YouTubeTranscriptApi.get_transcript(video_id)

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
        return {
            'success': False,
            'error': str(e)
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

    # Get and print transcript
    result = get_transcript(video_id)
    print(json.dumps(result))