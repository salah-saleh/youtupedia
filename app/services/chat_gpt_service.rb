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

  def self.answer_question(video_id, question, transcript)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    thread_data = ChatThreadService.create_or_load_thread(video_id)

    # Build conversation history
    messages = [
      {
        role: "system",
        content: <<~PROMPT
          You are a helpful assistant answering questions about a video transcript.
          Provide clear and concise answers based on the transcript content.
          PLease answer stictly about the transcript content.
          If asked about any other topic, please say you can only answer about the transcript content.
          Your response must be in markdown format.
        PROMPT
      },
      {
        role: "user",
        content: "Here is the transcript to analyze: #{transcript}"
      }
    ]

    # Add conversation history
    thread_data[:messages].each do |msg|
      messages << {
        role: msg[:role],
        content: msg[:content]
      }
    end

    # Add the new question
    messages << {
      role: "user",
      content: question
    }

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: messages,
        temperature: 0.7
      }
    )

    content = response.dig("choices", 0, "message", "content")
    return { success: false, error: "No content received" } unless content

    # Save the conversation
    ChatThreadService.save_message(video_id, "user", question)
    ChatThreadService.save_message(video_id, "assistant", content)

    { success: true, answer: content }
  rescue => e
    Rails.logger.error "Chat GPT Error: #{e.message}"
    { success: false, error: "Failed to process question: #{e.message}" }
  end

  private

  def self.generate_from_api(transcript)
    return { success: false, error: "Transcript is too short" } if transcript.length < 100

    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        # store: true,
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
      You will receive text with timestamps. for example:
      "we will speak about AI today (0.5) it is gonna be a long video (1.5)"
      For takeaways and tags you will need to give reference to the timestamp in seconds.
      For tldr, you will not need to give timestamps.
      For summary, you will need to give timestamps as reference. e.g. blah blah blah (0.5) blah blah blah (1.5).
      Your response must be in valid JSON format with the following schema:
      {
        "tldr": "brief one-paragraph summary",
        "takeaways": [
          {
            "timestamp": 45,
            "content": "takeaway 1"
          },
          {
            "timestamp": 120,
            "content": "takeaway 2"
          }
          // up to 19 takeaways
        ],
        "tags": [
          {
            "timestamp": 45,
            "tag": "tag1"
          },
          {
            "timestamp": 120,
            "tag": "tag2"
          }
          // up to 10 tags, focusing on names, technologies, concepts, tools and etc.
        ],
        "summary": "detailed 500-800 word summary"
      }
      Do not include any other text outside of this JSON structure.
      Always include timestamps in seconds for each takeaway and tag, representing when this concept first appears in the video.
    PROMPT
  end
end
