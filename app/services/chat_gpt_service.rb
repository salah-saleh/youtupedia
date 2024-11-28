class ChatGptService
  def self.generate_summary(video_id, transcript)
    cache_service = Cache::FileCacheService.new("summaries")

    cache_service.fetch(video_id) do
      generate_from_api(transcript)
    end
  rescue => e
    Rails.logger.error "Summary Error: #{e.message}"
    { success: false, error: "Failed to generate summary: #{e.message}" }
  end

  private

  def self.generate_from_api(transcript)
    return { success: false, error: "Transcript is too short" } if transcript.length < 100

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: "Please summarize this video transcript: #{transcript}"
          }
        ],
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    return { success: false, error: "No content received" } unless content

    result = JSON.parse(content)
    {
      success: true,
      tldr: result["tldr"],
      takeaways: result["takeaways"],
      tags: result["tags"],
      summary: result["summary"]
    }
  rescue JSON::ParserError => e
    { success: false, error: "Failed to parse response: #{e.message}" }
  end

  def self.system_prompt
    <<~PROMPT
      You are a helpful and creative Editor who analyzes transcripts.
      You focus on names, numbers, concepts, technologies, techniques, tools and etc.
      Your response must be in valid JSON format with the following schema:
      {
        "tldr": "brief one-paragraph summary",
        "takeaways": [
          "takeaway 1",
          "takeaway 2",
          // up to 19 takeaways
        ],
        "tags": [
          "tag1",
          "tag2",
          // up to 50 tags, focusing on names, technologies, concepts, tools and etc.
        ],
        "summary": "detailed 500-800 word summary"
      }
      Do not include any other text outside of this JSON structure.
    PROMPT
  end
end
