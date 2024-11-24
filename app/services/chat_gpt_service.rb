class ChatGptService
  CACHE_DIR = Rails.root.join("tmp/summaries")

  def self.generate_summary(video_id, transcript)
    # Create cache directory if it doesn't exist
    FileUtils.mkdir_p(CACHE_DIR) unless Dir.exist?(CACHE_DIR)

    cache_file = CACHE_DIR.join("#{video_id}.json")

    if File.exist?(cache_file)
      Rails.logger.debug("Loading summary from cache for video_id: #{video_id}")
      JSON.parse(File.read(cache_file), symbolize_names: true)
    else
      Rails.logger.debug("Generating new summary for video_id: #{video_id}")
      fetch_and_cache_summary(transcript, cache_file, video_id)
    end
  rescue => e
    Rails.logger.error "Summary Error: #{e.message}"
    { success: false, error: "Failed to generate summary: #{e.message}" }
  end

  private

  def self.fetch_and_cache_summary(transcript, cache_file, video_id)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    full_text = transcript
    # check if length is less than 100, throw error
    if full_text.length < 100
      return { success: false, error: "Transcript is too short to generate a summary" }
    end

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are a helpful and creative Editor who analyzes transcripts.
            You focus on names, numbers, concepts, technologies, techniques, tools and etc.
            Your response must be in valid JSON format with the following schema:
            {
              'tldr': 'brief one-paragraph summary',
              'takeaways': [
                'takeaway 1',
                'takeaway 2',
                // up to 10 takeaways
              ],
              'tags': [
                'tag1',
                'tag2',
                // up to 50 tags, focusing on names, technologies, concepts, tools and etc.
              ],
              'summary': 'detailed 500-800 word summary'
            }
            Do not include any other text outside of this JSON structure."
          },
          {
            role: "user",
            content: "Please summarize this video transcript: #{full_text}"
          }
        ],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    return { success: false, error: "No content received" } unless content

    result = JSON.parse(content)
    result = {
      success: true,
      tldr: result["tldr"],
      takeaways: result["takeaways"],
      tags: result["tags"],
      summary: result["summary"]
    }

    Rails.logger.debug("Caching summary for video_id: #{video_id}")
    File.write(cache_file, result.to_json)

    result
  rescue JSON::ParserError => e
    { success: false, error: "Failed to parse response: #{e.message}" }
  end
end
