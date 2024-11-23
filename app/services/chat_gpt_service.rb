class ChatGptService
  def self.generate_summary(transcript)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    # Debug log
    Rails.logger.debug "Starting ChatGPT summary generation..."

    # Convert transcript segments to plain text
    full_text = transcript.map { |segment| segment["text"] }.join(" ")

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are a helpful and creative Editor. Usually you work on analyzing podcast transcripts.
            You focus on names, numbers, concepts, technologies, techniques, tools and etc.
            Please provide: 1) A brief TLDR.
            2) up to 10 key takeaways.
            3) Relevant tags. Focus on names, numbers, concepts, technologies, techniques, and tools mentioned. Up to 50 tags are allowed.
            4) About 500 to 800 words of summary."
          },
          {
            role: "user",
            content: "Please summarize this video transcript: #{full_text}"
          }
        ],
        temperature: 0.7
      }
    )

    # Debug log
    Rails.logger.debug "ChatGPT Response received: #{response.inspect}"

    self.parse_response(response.dig("choices", 0, "message", "content"))
  rescue => e
    Rails.logger.error "ChatGPT API Error: #{e.message}"
    {
      success: false,
      error: "Failed to generate summary: #{e.message}"
    }
  end

  def self.parse_response(content)
    return { success: false, error: "No content received" } unless content

    # Debug log
    Rails.logger.debug "Parsing content: #{content}"

    {
      success: true,
      tldr: content.match(/TLDR:(.+?)(?=Key Takeaways:)/m)&.captures&.first&.strip || "tldr not available",
      takeaways: content.scan(/\d\.\s(.+?)(?=\d\.|Tags:|$)/m).flatten.map(&:strip) || [],
      tags: (content.match(/Tags:(.+)$/m)&.captures&.first&.strip&.scan(/#(\w+)/)&.flatten || []),
      summary: content.match(/Summary:(.+?)(?=Detailed Summary:)/m)&.captures&.first&.strip || "summary not available"
    }
  end
end
