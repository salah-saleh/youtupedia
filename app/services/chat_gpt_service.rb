class ChatGptService
  def self.generate_summary(transcript)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    Rails.logger.debug "Starting ChatGPT summary generation..."

    full_text = transcript.map { |segment| segment["text"] }.join(" ")

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

    Rails.logger.debug "ChatGPT Response received: #{response.inspect}"

    parse_json_response(response.dig("choices", 0, "message", "content"))
  rescue => e
    Rails.logger.error "ChatGPT API Error: #{e.message}"
    {
      success: false,
      error: "Failed to generate summary: #{e.message}"
    }
  end

  def self.parse_json_response(content)
    return { success: false, error: "No content received" } unless content

    Rails.logger.debug "Parsing content: #{content}"

    parsed = JSON.parse(content)
    {
      success: true,
      tldr: parsed["tldr"],
      takeaways: parsed["takeaways"],
      tags: parsed["tags"],
      summary: parsed["summary"]
    }
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parsing error: #{e.message}"
    {
      success: false,
      error: "Failed to parse response: #{e.message}"
    }
  end
end
