class YoutubeTranscriptService
  def self.fetch_transcript(video_id)
    # Ensure to use the Python from our venv
    python_path = Rails.root.join("venv/bin/python")
    script_path = Rails.root.join("script/python/youtube_transcript.py")

    # Execute Python script and capture output
    output = `#{python_path} #{script_path} #{video_id}`

    # Parse JSON response
    JSON.parse(output)
  rescue JSON::ParserError => e
    { "success" => false, "error" => "Failed to parse transcript data" }
  rescue => e
    { "success" => false, "error" => e.message }
  end
end
